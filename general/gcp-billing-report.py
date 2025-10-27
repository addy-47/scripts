import smtplib
import os
import csv
import logging
from datetime import datetime, timedelta
from google.cloud import bigquery
from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText
from email.mime.base import MIMEBase
from email import encoders
from jinja2 import Template

# Configure logging
logging.basicConfig(
    level=logging.DEBUG,
    format="%(asctime)s - %(levelname)s - %(message)s",
    handlers=[
        logging.FileHandler("/tmp/billing_function.log"),
        logging.StreamHandler()
    ]
)

def render_html_table(data, headers, label, date_range):
    html_template = """
    <h2>{{ label }} Billing Report - {{ date_range }}</h2>
    <table>
        <thead>
            <tr>
                {% for header in headers %}<th>{{ header }}</th>{% endfor %}
            </tr>
        </thead>
        <tbody>
            {% for row in data %}
                <tr>
                    {% for col in row %}
                        <td {% if col == '₹0.00' %}class="zero-value"{% endif %}>{{ col }}</td>
                    {% endfor %}
                </tr>
            {% endfor %}
        </tbody>
    </table>
    """
    template = Template(html_template)
    return template.render(label=label, date_range=date_range, data=data, headers=headers)

def run_bq_query(client, query_template, table_path, start_date, end_date):
    query = query_template.replace("{{TABLE_PATH}}", table_path)
    job_config = bigquery.QueryJobConfig(
        query_parameters=[
            bigquery.ScalarQueryParameter("start_date", "DATE", start_date),
            bigquery.ScalarQueryParameter("end_date", "DATE", end_date),
        ]
    )
    return list(client.query(query, job_config=job_config).result())

def process_query_results(results):
    all_services = set()
    data_by_date = {}
    service_totals = {}

    for row in results:
        date = row["Date"]
        if date not in data_by_date:
            data_by_date[date] = {"Date": date, "Services": {}, "Per_Day_Total": float(row["Per_Day_Total"] or 0.0)}
        services = {svc["Service Name"]: float(svc["Cost"] or 0.0) for svc in row["Services"]}
        data_by_date[date]["Services"].update(services)
        all_services.update(services.keys())
        if date != "Total":
            for s, c in services.items():
                service_totals[s] = service_totals.get(s, 0.0) + c

    sorted_services = [s for s, _ in sorted(service_totals.items(), key=lambda x: x[1], reverse=True)]
    headers = ["Date"] + sorted_services + ["Per Day Total"]
    table_data = []

    for date in sorted(data_by_date.keys(), key=lambda x: ('1' if x == 'Total' else '0', x), reverse=True):
        row_data = data_by_date[date]
        row = [date] + [f"\u20b9{row_data['Services'].get(s, 0.00):.2f}" for s in sorted_services] + [f"\u20b9{row_data['Per_Day_Total']:.2f}"]
        table_data.append(row)

    return headers, table_data

def write_csv(file_path, headers, table_data):
    with open(file_path, 'w', newline='') as csvfile:
        writer = csv.writer(csvfile)
        writer.writerow(headers)
        writer.writerows(table_data)

def send_billing_report(request):
    logging.info("Starting billing report generation...")
    client = bigquery.Client()
    today = datetime.now()
    is_first_of_month = today.day == 1

    if is_first_of_month:
        first_day = (today.replace(day=1) - timedelta(days=1)).replace(day=1)
        last_day = today.replace(day=1) - timedelta(days=1)
        mode = "Monthly Summary"
        file_prefix = "monthly_report"
    else:
        first_day = today.replace(day=1)
        last_day = today - timedelta(days=1)
        mode = "Daily Billing - muxly + hypr4"
        file_prefix = "daily_report"

    start_date = first_day.strftime("%Y-%m-%d")
    end_date = last_day.strftime("%Y-%m-%d")
    date_range_str = f"{start_date} to {end_date}"

    QUERY_TEMPLATE = """
    WITH service_data AS (
        SELECT
            FORMAT_DATE('%Y-%m-%d', DATE(usage_start_time, "Asia/Kolkata")) AS `Date`,
            service.description AS `Service Name`,
            SUM(CAST(cost AS NUMERIC)) AS `Cost`
        FROM `{{TABLE_PATH}}`
        WHERE 
            cost_type NOT IN ('tax', 'adjustment')
            AND DATE(usage_start_time, "Asia/Kolkata") BETWEEN DATE(@start_date) AND DATE(@end_date)
        GROUP BY `Date`, `Service Name`
    ),
    pivoted_data AS (
        SELECT
            `Date`,
            ARRAY_AGG(STRUCT(`Service Name`, `Cost`)) AS `Services`,
            SUM(`Cost`) AS `Per_Day_Total`
        FROM service_data
        GROUP BY `Date`
    ),
    service_totals AS (
        SELECT
            `Service Name`,
            SUM(`Cost`) AS `Total_Cost`
        FROM service_data
        GROUP BY `Service Name`
        HAVING `Total_Cost` > 0
    ),
    all_data AS (
        SELECT `Date`, `Services`, `Per_Day_Total` FROM pivoted_data
        UNION ALL
        SELECT 'Total' AS `Date`, ARRAY_AGG(STRUCT(`Service Name`, `Total_Cost`)), SUM(`Total_Cost`) FROM service_totals
    )
    SELECT * FROM all_data
    ORDER BY CASE WHEN `Date` = 'Total' THEN 1 ELSE 0 END, `Date` DESC;
    """

    # Replace these with your actual BQ export table paths
    muxly_table = "your_bq_table_url"
    hypr4_table = "your_bq_table_url"

    # Run both queries
    results_muxly = run_bq_query(client, QUERY_TEMPLATE, muxly_table, start_date, end_date)
    results_hypr4 = run_bq_query(client, QUERY_TEMPLATE, hypr4_table, start_date, end_date)

    # Process both results
    headers_muxly, data_muxly = process_query_results(results_muxly)
    headers_hypr4, data_hypr4 = process_query_results(results_hypr4)

    # Write CSV files
    csv_path_muxly = f"/tmp/{file_prefix}_muxly_{start_date}_to_{end_date}.csv"
    csv_path_hypr4 = f"/tmp/{file_prefix}_hypr4_{start_date}_to_{end_date}.csv"
    write_csv(csv_path_muxly, headers_muxly, data_muxly)
    write_csv(csv_path_hypr4, headers_hypr4, data_hypr4)

    # Render HTML
    html_muxly = render_html_table(data_muxly, headers_muxly, "Muxly", date_range_str)
    html_hypr4 = render_html_table(data_hypr4, headers_hypr4, "Hypr4", date_range_str)
    email_body = f"""
    <html>
    <head>
        <style>
            body {{ font-family: Arial, sans-serif; margin: 20px; }}
            table {{ width: 100%; border-collapse: collapse; }}
            th, td {{ padding: 10px; border: 1px solid #ddd; text-align: right; }}
            th {{ background-color: #3498db; color: white; }}
            td:first-child, th:first-child {{ text-align: left; }}
            tr:nth-child(even) {{ background-color: #f9f9f9; }}
            tr:last-child {{ background-color: #2ecc71; color: white; font-weight: bold; }}
            .zero-value {{ color: #aaa; }}
        </style>
    </head>
    <body>
        {html_muxly}
        <hr/>
        {html_hypr4}
    </body>
    </html>
    """

    # Email credentials
    sender_email = os.getenv("SENDER_EMAIL")
    sender_password = os.getenv("SENDER_PASSWORD")
    recipient_emails = [e.strip() for e in os.getenv("RECIPIENT_EMAILS", "").split(",") if e.strip()]

    if not sender_email or not sender_password or not recipient_emails:
        logging.error("Missing email configuration.")
        return "Error: Missing email credentials or recipient emails."

    msg = MIMEMultipart()
    msg['From'] = sender_email
    msg['To'] = ", ".join(recipient_emails)
    msg['Subject'] = f"GCP Billing Report - {mode} ({date_range_str})"

    msg.attach(MIMEText(email_body, 'html'))

    for path in [csv_path_muxly, csv_path_hypr4]:
        with open(path, "rb") as attachment:
            part = MIMEBase("application", "octet-stream")
            part.set_payload(attachment.read())
            encoders.encode_base64(part)
            part.add_header("Content-Disposition", f"attachment; filename={os.path.basename(path)}")
            msg.attach(part)

    try:
        with smtplib.SMTP("smtp.gmail.com", 587) as server:
            server.starttls()
            server.login(sender_email, sender_password)
            server.sendmail(sender_email, recipient_emails, msg.as_string())
        logging.info("Email sent successfully.")
    except Exception as e:
        logging.error("Failed to send email: %s", str(e))
        return f"Failed to send email: {str(e)}"

    os.remove(csv_path_muxly)
    os.remove(csv_path_hypr4)
    logging.debug("Temporary files deleted.")
    return "Billing report sent successfully."

def main():
    logging.info("Script started.")
    result = send_billing_report({})
    print(result)
    logging.info("Script finished.")

if __name__ == "__main__":
    main()
