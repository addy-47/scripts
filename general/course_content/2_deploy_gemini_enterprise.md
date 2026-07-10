# Deploy the Gemini Enterprise App to Transform Enterprises

## Course introduction
*Type: section*

## Course Introduction
*Type: blocks*

### Text

Welcome
Welcome to the Deploy the Gemini Enterprise App to Transform Enterprises&nbsp; course. This course covers the technical side of deploying the Gemini Enterprise app. It discusses the overall architecture of Gemini Enterprise, decisions to be made when provisioning the app infrastructure, and integrating enterprise data via Data Stores, Connectors and Actions. The course also explores the kinds of agents that can be added to Gemini Enterprise. It offers guidance towards establishing a security perimeter using IAM, VPC Service Control, Context-Aware Access, and semantic controls deployed with Model Armor. Finally, it empowers administrators to fine-tune the end-user experience through comprehensive configuration options, and&nbsp; explains how administrators keep AI deployments secure, compliant, and performant through OpenTelemetry instrumentation and prompt logging. Gemini Enterprise&nbsp;supercharges enterprises, and brings the power of Google Search and AI to other organizations. It is the single intelligent hub designed to accelerate modern knowledge work, and includes features such as:

### List

One Search Bar, Every Data Source: &nbsp;You can instantly retrieve specific answers across your documents, emails, chats, and ticketing systems.

Your Creative Partner: &nbsp;You can brainstorm campaigns, research deeply, and draft comprehensive document outlines in seconds.

Action-Oriented AI: &nbsp;You can automate the busywork, like generating calendar invites and coordinating with colleagues so you can focus on high-impact collaboration.

### Text

Who this course is for?
This course is designed for:

### List

Customers

Partners

### Text

Prerequisites
There are no prerequisites r equired for this course.&nbsp;

### Text

Course objectives
In this course, you'll learn to:

### Image

✓ &nbsp; Deploy a Gemini Enterprise app. ✓ &nbsp;&nbsp; Configure an identity provider for authorization. ✓ &nbsp;&nbsp; Grant access to Google Workspace data stores. ✓ &nbsp;&nbsp; Customize and configure your deployment according to security best practices.

## architecture overview
*Type: section*

## Module Introduction 
*Type: blocks*

### Text

Welcome to this module, Architecture Overview .&nbsp; The Architecture Overview module explores how the assistant connects to Workspace data and ingested or federated third-party data stores, and how data store actions and agents can help Gemini Enterprise complete tasks in addition to reporting on data. In this module, you'll learn to:&nbsp;

### List

Describe how Gemini Enterprise addresses the challenge of information discovery in organizations.

Analyze the blueprint for deploying Gemini Enterprise by explaining the flow from the user interface to agentic actions.

## Architecture Overview
*Type: blocks*

### Text

Let's begin by introducing Gemini Enterprise.&nbsp;

### Text

Click the play button to watch the video. &nbsp;

### Text

Enterprise data sources
At its core, the Gemini Enterprise architecture is designed to seamlessly connect you with information from your organization or the web.

### Text

When you submit a prompt through the unified chat interface, Gemini Enterprise retrieves relevant information from your connected enterprise systems to generate a grounded result.

### Text

Click each flashcard to learn more.

### Text

Accessing data with ingestion or federation

### Image

When architecting Gemini Enterprise access to enterprise data stored in third-party systems (not on Google Cloud or in Google Workspace data stores), you may be asked to choose between two primary data retrieval patterns, namely, Ingestion or Federation .

### Text

Data Ingestion
With data Ingestion, your data, along with its associated Access Control Lists (ACLs), is actively pulled from the source systems and securely indexed into dedicated Data Stores within Google Cloud.

### Text

Because the data is stored and processed natively within the Google Cloud perimeter , this method typically yields the fastest query latency . The system respects the ingested ACLs at query time, ensuring users only receive answers generated from documents they have explicit permission to view .

### Text

Search Federation&nbsp;
Search Federation, also known as real-time or live federation , leaves your data entirely within its original source system .

### Text

Instead of indexing the data beforehand, Gemini Enterprise translates the user's prompt into a live query against the external system's API. The external system processes the query , enforces access controls natively, and returns the relevant data back to Gemini Enterprise to ground the final response.

This zero-copy architecture is highly advantageous for organizations dealing with strictly regulated , highly sensitive , or rapidly changing data where creating a secondary index is not permissible. It also avoids the duplicate storage costs and managing additional periodic data ingestion complexities .

### Text

Taking actions
The capabilities of Gemini Enterprise extend beyond retrieving and summarizing information as it is also designed to execute tasks .&nbsp; Some Google-provided data stores allow you to enable actions, which allow Gemini Enterprise to make OAuth-authenticated calls to external tools and APIs on a user’s behalf. You can ask Gemini to:

### List

draft and send emails,

schedule calendar events, or

update bug tickets in third-party tracking systems directly from the chat interface.

### Text

Summary
Understanding this flow from the user interface, through the reasoning engine, down to the ingested or federated data stores, and back out through agentic actions, forms the blueprint for deploying Gemini Enterprise. With this architectural foundation established, further modules will explore the specific networking, identity, and security configurations required to bring this ecosystem to life safely and effectively.

## provisioning 
*Type: section*

## Module Introduction
*Type: blocks*

### Text

Welcome to this module, Provisioning . The Provisioning module explains the steps for provisioning the Gemini Enterprise infrastructure within Google Cloud, including assigning necessary IAM roles and following specific deployment pathways based on the organization's existing use of Google Cloud and Google Workspace. In this module, you'll learn to:&nbsp;

### List

Identify the critical steps for provisioning the Gemini Enterprise infrastructure within Google Cloud.

List the necessary steps for assigning IAM roles and following specific deployment pathways.

## Provisioning
*Type: blocks*

### Text

I AM permissions
To configure the application, data stores, and actions securely, administrators must be assigned specific Identity and Access Management (IAM) roles .

### Image

The provisioning administrator requires the Discovery Engine Admin role, the OAuth Config Editor role to properly configure the consent screen for actions, and the Service Usage Admin role to enable any necessary underlying APIs.&nbsp; For end-users to access the Gemini Enterprise app, they must be granted the Discovery Engine User role.

### Text

Provisioning
The provisioning pathway for Gemini Enterprise depends on your organization's existing infrastructure: particularly whether you are an existing Google Cloud customer and whether you utilize Google Workspace.&nbsp;

### Text

O rganizations already using Google Cloud
If an organization already uses Google Cloud and intends to connect Google Workspace data, such as Gmail or Google Drive, both Gemini Enterprise and Google Workspace must reside within the same Google Cloud Organization . Adhering to this ' Google Workspace Connector Rule ' &nbsp; is crucial. Failing to align them in the same organization requires complex cross-tenant allowlisting to enable integration.

### Text

O rganizations currently not using Google Cloud
For organizations that do not currently have a Google Cloud environment, Google offers tailored onboarding paths .

### Text

Click each + button to expand the items and learn more. &nbsp;

### Text

Summary
Successfully deploying Gemini Enterprise relies on enabling the underlying. By assigning the correct IAM roles such as Discovery Engine Admin, OAuth Config Editor, and Service Usage Admin, organizations can enable the necessary APIs and establish a secure, foundational environment ready to connect users with intelligent, agentic capabilities.

## networking 
*Type: section*

## Module Introduction 
*Type: blocks*

### Text

Welcome to this module, Networking . The Networking module explains the steps for securing the Gemini Enterprise network perimeter using Virtual Private Service Controls and Context-Aware Access, and optimizing network traffic flows to handle the demands of generative AI models. In this module, you'll learn to:&nbsp;

### List

Explain how to apply Virtual Private Service Controls and Context-Aware Access to secure the Gemini Enterprise network perimeter.

Define how to optimize network traffic flows to handle the demands of generative AI models.

## Networking
*Type: blocks*

### Text

Once the environment is provisioned and identities are established, securing the network perimeter and optimizing traffic flows become the next critical focus.

### Text

Virtual Private Service Control
Gemini Enterprise can be integrated with Virtual Private Cloud Service Controls (VPC-SC).

### Image

This powerful security feature allows administrators to draw a virtual service perimeter around managed cloud services , including Cloud Storage, BigQuery, and Gemini Enterprise itself. This perimeter acts as a secure boundary that isolates your data and AI interactions from unauthorized networks, preventing data exfiltration.

### Text

Example
For example, consider a financial institution using Gemini Enterprise to summarize sensitive revenue data stored in BigQuery.

### Text

Context-Aware Access
Complementing this perimeter is Context-Aware Access, which introduces a Zero Trust security layer to your deployment.

### Image

Rather than relying solely on traditional user credentials, Context-Aware Access dynamically evaluates a user's real-time context , such as their device health , geographic location , and current network state , before granting or denying access to resources.

### Text

When combined with VPC Service Controls and Identity and Access Management , this ensures that only validated users on trusted devices can interact with your enterprise AI environment.

### Text

Network consideration&nbsp;
Generative AI models require more processing time than traditional web applications, often exceeding standard 30-second network timeouts .To prevent corporate load balancers and firewalls from prematurely dropping these connections , network engineers must adapt their infrastructure . Key strategies include:

### Text

Click each flashcard to learn more.

### Text

Summary
A well-architected Gemini Enterprise deployment hinges on thoughtful networking considerations and adjustments to help optimize, secure and make the application more accessible.

## User Identity and Access Management 
*Type: section*

## Module Introduction 
*Type: blocks*

### Text

Welcome to this module, User Identity and Access Management module . The User Identity and Access Management module deals with the essential task of establishing a secure identity and access management foundation for Gemini Enterprise by selecting the appropriate identity provider and assigning necessary IAM roles is also addressed. In this module, you'll learn to:&nbsp;

### List

Explain how to select an appropriate identity provider for Gemini Enterprise.

State how to assign necessary IAM roles to establish a secure identity and access management foundation.

## User Identity and Access Management 
*Type: blocks*

### Text

With the network perimeter secured, the next critical decision is to select the correct identity provider for your deployment.&nbsp;

### Image

Your chosen identity configuration directly dictates how end - users authenticate and how the AI system enforces document-level permissions . The architecture demands a specific identity strategy depending on the data stores your organization plans to utilize.

### Text

Identity providers&nbsp;
Let's explore &nbsp; the requirements for choosing an Identity Provider for a Gemini Enterprise deployment based on its integration needs.&nbsp;

### Text

Click each tab to learn more. &nbsp;

### Text

Access boundaries
Administrators must carefully manage access boundaries within Google Cloud.

### Text

I AM roles and responsibilities&nbsp;
To effectively manage and secure a Gemini Enterprise deployment, organizations should assign Identity and Access Management (IAM) roles according to user tasks.

### Text

At the highest level, the Security or IAM Administrator operates with the Organization Admin role. This administrator is responsible for configuring Workforce Identity Federation and granting the necessary IAM permissions to Gemini Enterprise administrators and user groups, often utilizing automation tools like Terraform for scalable rollouts.

### Text

Once the foundation is laid, an engineer dedicated to the Gemini Enterprise deployment can take over the application configuration using the Discovery Engine Admin role. This role provides the permissions necessary to create data connectors , configure the Gemini Enterprise user interface , establish agentic actions , and build the core applications . It is important to note that deploying agents will require additional permissions , such as the Agent Platform User role to deploy agents to Agent Runtime.

### Text

Finally, the general workforce interacting with the platform operates as End Users with the Gemini Enterprise User role. This role provides access to the deployed Gemini Enterprise app . With this role, users can execute searches across all authorized connectors , interact with pre-created agents , and utilize actions defined by the administrator , provided they have the correct underlying permissions for those&nbsp;specific applications and data sources.

### Text

Summary
A secure Gemini Enterprise deployment relies on a strong identity and access management foundation. Organizations can establish safe, permission-aware access for their entire workforce by selecting the appropriate identity provider—Google Identity or Workforce Identity Federation—and assigning specific IAM roles like Discovery Engine Admin and User.

## Data stores 
*Type: section*

## Module Introduction 
*Type: blocks*

### Text

Welcome to this module, Data Stores . The Data Stores module explains the fundamental infrastructure of Data Stores and Connectors, which explains how they integrate Gemini Enterprise with data through various connection modes like ingestion and federation to enable grounded responses and agentic workflows. In this module, you'll learn to:&nbsp;

### List

Describe the critical infrastructure of Data Stores and Connectors.

Explain how Data Stores and Connectors integrate enterprise data through ingestion and federation to enable grounded responses and agentic workflows.

## Data Stores
*Type: blocks*

### Text

Data Stores grant Gemini Enterprise access to generate responses grounded in your enterprise data and take appropriate actions.&nbsp; You may also encounter the term ‘ Connectors ’, which serve as the active transport mechanism, securely ingesting or querying data. Once data is retrieved, it is housed within a Data Store – a secure, centralized, and highly structured AI-ready database. In practice, these terms are often used interchangeably.

### Text

Click each flashcard to learn more.

### Text

Google provides a variety of pre-built data stores to popular first and third party systems.

### Image

View the latest list of third-party data stores, paying attention to the release stages of each, in the official Google Cloud documentation title: Connect a third-party data source .

### Text

Connection mode
Federated mode connectors, also known as real-time or zero-copy connectors , leave the data strictly within its original source system.

### Image

In this mode, Gemini Enterprise translates the user's prompt , and queries the external API live .&nbsp; This approach is highly favored by information security teams because no proprietary data is copied into a secondary cloud index , and permissions are enforced natively by the source system during the live query.

### Text

Federated mode also offers turnkey onboarding , requires fewer OAuth scopes , and guarantees that the information retrieved is always one-hundred percent up-to-date . The trade-off is that query latency can be slower and variable , as Gemini is entirely dependent on the response time and payload limits of the external system's API.

### Text

Alternative integrations
If a pre-built connection is not available for a specific proprietary system, organizations have alternative integration strategies.

### Text

Click each tab to learn more. &nbsp;

### Text

Setup
Now let's explore setup.&nbsp;

### Text

Click each flashcard to learn more.

### Text

Deployment best practices
Deploying these connectors successfully requires rigorous testing and adherence to deployment best practices.

### Text

Click each checkbox list.

### List

Administrators should never assume a connector will work flawlessly out of the box, especially if that connector is not yet listed as Generally Available in the third-party connectors documentation .

Instead, they must de-risk the deployment by conducting technical pre-flight checks to confirm all IAM permissions and access policies are correctly applied.

When scaling, it is highly recommended to start small by mastering a single connector before introducing the complexity of multiple data streams.

Finally, when initiating user testing, administrators must verify that the testers actually possess the required permissions within the source system; otherwise, testers may encounter missing data and falsely report that the Gemini integration is broken.

### Text

Data + action
Some 1st party data stores feature agentic workflows when they are being set up.

### Text

Human-in-the-loop approval
Google's architecture ensures security and accuracy by enforcing a strict 'human-in-the-loop' approach for these agentic capabilities . When a user prompts Gemini Enterprise to create a calendar event or compose an email , the system does not execute the action unchecked in the background. Instead, the following takes place:&nbsp;

### List

The assistant generates a structured draft and presents it to the user directly within the chat interface.

The user is provided the opportunity to review the content and modify fields as necessary.

The user explicitly clicks to authorize the final execution.

### Text

This crucial validation step guarantees that all AI-generated actions remain entirely under human supervision before impacting external systems.

### Text

Summary
Connectors and Data Stores serve as the critical infrastructure that transforms Gemini Enterprise into a highly contextualized reasoning engine for your organization. We recommend taking a proactive, phased approach to ensure a smooth and successful rollout with data connectors. You’ll minimize risks and set your project up for immediate success by validating capabilities upfront, conducting technical pre-flight checks to confirm all IAM permissions and access policies are correctly applied, and mastering one connector before scaling.

## agents 
*Type: section*

## Module Introduction 
*Type: blocks*

### Text

Welcome to this module, Agents . The Agents module explores the shift from simple chatbots to Gemini Enterprise Agents, which are active digital workers capable of multi-step workflows, leveraging a creation spectrum that ranges from no-code Agent Designer to high-code Agent Engine, all under centralized governance. In this module, you'll learn to:&nbsp;

### List

Differentiate between simple chatbots and Gemini Enterprise Agents, which are active digital workers capable of multi-step workflows.

Evaluate the development spectrum that ranges from no-code Agent Designer to high-code Agent Engine, all under centralized governance.

## Agents
*Type: blocks*

### Text

Gemini Enterprise provides a foundation for Agents, which are active digital workers capable of executing multi-step workflows across your enterprise systems on your behalf.

### Text

The shift from chatbots to agents
An agent moves beyond simply answering questions. It is characterized by its ability to:

### Text

Click each flashcard to learn more.

### Text

The agent development spectrum&nbsp;
Gemini Enterprise provides a platform that supports agent creation for every technical skill level:

### Text

Click each + button to expand the items and learn more &nbsp;

### Text

Types of agents in Gemini Enterprise

### Text

Centralized governance and discovery
Managing an array of digital workers requires enterprise-grade oversight . &nbsp; Administrators gain centralized visibility and control, ensuring every agent operates under security guidelines and AI Protection guardrails.

### Text

For the end-user , these agents are easily discoverable. Users can type @ in the search bar to call an agent into their current conversation , or browse the dedicated Agent Gallery , which categorizes digital workers into:

### Text

Enabling agent actions with OAuth

### Image

To enable agents to actively execute workflows like updating a CRM record or sending an email , Gemini Enterprise uses OAuth (Open Authorization). OAuth is like a digital ' valet key ,' as it allows your agents to securely interact with external systems on your user’s behalf without ever needing their actual password .

### Text

Click each tab to learn more. &nbsp;

### Text

Summary
Agents are active digital workers from Gemini Enterprise that execute multi-step workflows across enterprise systems. They move beyond simple chatbots by using reasoning and tools to perform complex, specific business functions. All agents operate under centralized governance. Their ability to execute actions is securely enabled by OAuth, which ensures granular permissions, user consent, and maintains a 'Human-in-the-Loop' for final action approval.

## model armor 
*Type: section*

## Module Introduction 
*Type: blocks*

### Text

Welcome to this module, Model Armor . The Model Armor module covers a robust security feature designed to protect generative AI models by inspecting and sanitizing user inputs and model outputs using customizable filters and thresholds to prevent data leakage and malicious attacks. In this module, you'll learn to:&nbsp;

### List

Describe how to utilize Model Armor to protect generative AI models by inspecting and sanitizing user inputs and model outputs.

Explain how to configure customizable filters and thresholds to prevent data leakage and malicious attacks.

## Model Armor
*Type: blocks*

### Text

With great capability comes the need for serious security.

### Image

When deploying a generative AI solution, organizations must ensure that the AI does not inadvertently leak sensitive data , generate inappropriate responses , or fall victim to malicious user prompts . To address these risks, administrators should implement Model Armor , a robust security feature that acts as a protective shield around your generative AI models.

### Text

Model Armor works by sitting squarely between the end-user and the Large Language Model (LLM). It continuously inspects both the input (the user's prompt) and the output (the model's generated response), sanitizing the data in transit before it reaches its destination. To provide comprehensive protection, Model Armor utilizes a series of customizable filters, including:

### Text

Click each flashcard to learn more.

### Text

Decoupling templates and adjusting thresholds
Model Armor allows administrators to set specific thresholds, such as High , Moderate , or Low , which dictate the confidence level required to flag a violation .

### Text

A High threshold is recommended for production environments as it minimizes false positives and ensures uninterrupted user interactions.

While a&nbsp; Low threshold is highly restrictive and should be used with caution.

### Text

Decouple templates
Crucially, administrators can and should decouple the rules applied to inputs from the rules applied to outputs using the following distinct templates:

### Text

Deployment best practices

### Text

Floor settings &nbsp;
Finally, organizations can establish a baseline security posture by using ' Floor Setting Conformance .'&nbsp; This allows security teams to dictate minimum safety thresholds globally at the Organization , Folder , or Project level, ensuring that no individual Gemini application can bypass the company's foundational safety requirements.

### Text

There is an important nuance to this feature: local settings are always applied alongside the organizational baseline.

### Text

This means that while an individual application administrator cannot lower or bypass the mandated global safety floor (e.g., changing a required ' Medium ' hate speech filter to ' Off '), they are still empowered to apply stricter local settings .

For instance, they can increase the threshold to ' High ' for their specific app or introduce custom dictionary filters . Gemini Enterprise evaluates both the global floor and the local configuration , enforcing the most restrictive ruleset. This guarantees corporate compliance while preserving the flexibility needed for app-specific safety tuning .

### Image

For instance, they can increase the threshold to ' High ' for their specific app or introduce custom dictionary filters . Gemini Enterprise evaluates both the global floor and the local configuration , enforcing the most restrictive ruleset. This guarantees corporate compliance while preserving the flexibility needed for app-specific safety tuning .

### Text

Summary
Model Armor is a robust security feature that protects generative AI by inspecting and sanitizing both the user's input prompt and the model's output. It uses customizable filters for sensitive data, prompt injection, and content safety to prevent data leaks and harmful content. Administrators can set rules and thresholds, ensuring local settings comply with a global security floor but can be made stricter.

## Configurations and Customizations 
*Type: section*

## Module Introduction 
*Type: blocks*

### Text

Welcome to this module, Configurations and Customizations . The Configurations and Customizations module describes how administrators can fine-tune the end-user experience of Gemini Enterprise by configuring options to customize the interface, modify search behavior, govern feature access, and monitor adoption. In this module, you'll learn to:&nbsp;

### List

Describe how to configure options to customize the Gemini Enterprise interface.

Define how to configure options to modify search behavior.

Explain how to configure options to govern feature access.

Summarize how to configure options to monitor adoption.

## Configurations and Customizations
*Type: blocks*

### Text

Once the core architecture, identity boundaries, and security perimeters are established, administrators can fine-tune the end-user experience . Gemini Enterprise provides a robust suite of configuration options to customize the interface , modify search behavior , govern feature access , and monitor adoption .

### Text

Let's explore a few notable settings.

### Text

Search UI tab

### Text

You can white-label the web application with a custom corporate Logo Image URL .

### Text

Control tab

### Text

Click each tab to learn more. &nbsp;

### Text

Assistant settings tab&nbsp;

### Text

Click each + button to expand the items and learn more. &nbsp;

### Text

Knowledge graph&nbsp;
Let's explore what a knowledge graph is.&nbsp;

### Image

A knowledge graph is a structured network that maps out the underlying relationships between different data points (like people, documents, and concepts) to provide deeper contextual understanding. Rather than just matching keywords, it connects entities like nodes on a web , allowing the AI to understand the meaning and context behind a query .

### Text

Click each tab to learn more. &nbsp;

### Text

Feature management &nbsp;

### Text

Click each flashcard to learn more.

### Text

Summary
Configurations and Customizations provides administrators with a suite of options to fine-tune the Gemini Enterprise experience, including customizing the interface, controlling search relevance, defining the assistant's tone and behavior, and managing feature access.

## Governance and Observability
*Type: section*

## Module Introduction 
*Type: blocks*

### Text

Welcome to this module, Governance and Observability . The Governance and Observability module describes how administrators can ensure their AI deployment remains secure, compliant, and performant by maintaining visibility and continuous control through enabling OpenTelemetry traces and logs instrumentation and enabling the logging of full prompt inputs and response outputs. In this module, you'll learn to:&nbsp;

### List

Describe the role of Governance and Observability in securing and scaling Gemini Enterprise.

Distinguish between the two Observability settings and explain the data privacy and prerequisite considerations for logging PII.

## Governance and Observability
*Type: blocks*

### Image

As Gemini Enterprise scales across an organization, maintaining visibility and continuous control is paramount. Governance and observability ensure that your AI deployment remains secure , compliant , and performant while delivering measurable business value.

### Text

Observability
Under the Configuration tab of your Gemini App , you will find the Observability tab . You can turn the following settings on or off.

### Text

Click each + button to expand the items and learn more. &nbsp;

### Text

Enabling the logging of prompt inputs and response outputs ensures Cloud Logging captures the full content of both user prompts and model responses.

### Text

It's important to take note of the following:

### Text

Click each flashcard to learn more.

### Text

Enable instrumentation of OpenTelemetry traces and logs &nbsp;setting.&nbsp;

### Image

To learn more about the specific information logged visit the following link in the official Google Cloud documentation:&nbsp; Access Gemini Enterprise usage audit logs with Cloud Logging .

### Text

Summary
Governance and Observability are vital for secure Gemini Enterprise scaling. Observability features enable two key logging settings: OpenTelemetry instrumentation (traces, logs, and metrics) and full prompt and response logging (including PII). The latter requires the former and necessitates user consent and restricted log access due to sensitive data. Logs are viewed in Google Cloud's Logs Explorer.

## course conclusion and summary
*Type: section*

## Course conclusion
*Type: blocks*

### Text

Gemini Enterprise is designed to serve as the unified, intelligent hub for modern knowledge work, transforming scattered enterprise data into a streamlined, contextual command center. By connecting diverse data sources, from Google Workspace apps to third-party platforms, it provides a single search bar that instantly retrieves specific answers across documents, emails, chats, and ticketing systems. More than just a passive search engine, Gemini Enterprise acts as a proactive 'Digital Chief of Staff' and the front door to an agentic workplace. It empowers users to transition from simply finding information to executing complex tasks directly within the chat interface, such as drafting emails, updating bug tickets, or scheduling calendar events. This powerful combination of intelligent data retrieval and secure, human-supervised workflow automation allows employees to eliminate busywork and focus on high-impact collaboration, all while operating under robust security and centralized governance.

## Course summary
*Type: blocks*

### Text

Congratulations! You have completed the course, Deploy the Gemini Enterprise app to Transform Enterprises . By completing this course, you should now be able to:

### Image

✓ &nbsp;&nbsp;&nbsp; Deploy a Gemini Enterprise app. ✓ &nbsp;&nbsp; Configure an identity provider for authorization. ✓ &nbsp;&nbsp; Grant access to Google Workspace data stores. ✓ &nbsp;&nbsp; Customize and configure your deployment according to security best practices.
