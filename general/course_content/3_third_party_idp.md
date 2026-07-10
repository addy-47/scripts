# Use a Third-Party Identity Provider with Workforce Identity Federation

## introduction
*Type: section*

## Course introduction
*Type: blocks*

### Text

Welcome to the course Use a Third-Party Identity Provider with Workforce Identity Federation . This course provides learners the knowledge to configure Workforce Identity Federation to grant Google Cloud and Gemini Enterprise access to users that authenticate using a third-party Identity Provider. The curriculum includes theory and demo videos covering workforce identity pools, OIDC and SAML providers, attribute mapping, IAM policies, and troubleshooting guidance. This course is designed for Cloud Architects , Security Engineers and Engineers deploying Gemini Enterprise , who have a basic understanding of Google Cloud IAM and authentication. In this course you will learn how to:

### Image

✓&nbsp; &nbsp; Describe the architecture and token exchange flow of Workforce Identity Federation (WIF). ✓&nbsp; &nbsp; Configure Workforce Identity Pools and Providers for both SAML 2.0 and OIDC. ✓ &nbsp;&nbsp; Implement attribute mapping and write CEL logic for access conditions. ✓ &nbsp;&nbsp; Bind IAM policies to federated identities. ✓ &nbsp;&nbsp; Utilize CLI/API access and investigate authentication logs.

## Foundations and Architecture
*Type: section*

## The identity challenge
*Type: blocks*

### Text

Learning objectives
By the end of this lesson, you will be able to:

### Image

✓&nbsp; &nbsp; Articulate the specific use case for Workforce Identity Federation (WIF). ✓ &nbsp;&nbsp; Distinguish between Cloud Identity, Workload Identity, and Workforce Identity.

### Text

The Scenario: The "GlobalTech" Merger
Welcome to your new role. You are a Cloud Architect at GlobalTech. It is 9:00 AM on a Tuesday. Your CTO walks in with news: GlobalTech is partnering with PartnerCorp to build a new application.

### List

The Requirement: 500 PartnerCorp developers need immediate access to your Google Cloud projects to view logs and upload code.

The Constraint: PartnerCorp uses Okta &nbsp;for their login. They do not have, and do not want, Google/Gmail accounts.

The Timeline: They need access by Thursday.

### Text

Your challenge: How do you grant the PartnerCorp developers access?
When we show up to the present moment with all of our senses, we invite the world to fill us with joy. The pains of the past are behind us. The future has yet to unfold. But the now is full of beauty simply waiting for our attention.

### Text

The "old way" (the anti-pattern) In the past, you might have solved this by using Google Cloud Identity (GCI) .

### List

You create 500 new Google accounts (such as, dev1@globaltech.com ) or use Google Cloud Directory Sync (GCDS) to keep the accounts in sync.

If you create 500 new Google accounts then you would need to email the credentials to 500 people.

### Text

Why this fails

### List

Security Risk : If a developer leaves PartnerCorp, their Okta account is disabled, but their GlobalTech Google account might remain active (a "Zombie Account").

Overhead : You are now managing the lifecycle of 500 extra users.

Cost : Depending on your license, you might pay for these identities.

User Friction : The developers hate it. They have to manage a second set of credentials and 2FA tokens.

### Text

The Solution: Workforce Identity Federation
To grant 500 new, external users from PartnerCorp access,&nbsp;Workforce Identity Federation is the preferred solution because it shifts from Synchronization (copying users) to Federation (borrowing trust). Instead of creating a user in Google Cloud, you tell Google Cloud: "I trust PartnerCorp’s Okta for these 500 PartnerCorp developers. If PartnerCorp’s Okta says this developer is 'Jamie' and they are allowed to be here, let them in."

### Text

How it works (High Level):
When we show up to the present moment with all of our senses, we invite the world to fill us with joy. The pains of the past are behind us. The future has yet to unfold. But the now is full of beauty simply waiting for our attention.

### List

The user logs in to their system (Okta, Microsoft Entra ID, Ping, and others).

Their system gives them a "pass" (a token).

They show that "pass" to Google Cloud.

Google Cloud grants them temporary access to the console or API.

### Image

Key Takeaway The identity remains external. Google only manages the permissions, not the user.

### Text

Concept Distinction: Which "Identity" Solution?
Google Cloud has several similarly named services. Choosing the wrong one is a common architectural mistake. You can use this table to provide clarity:

### Text

Feature Cloud Identity Workload Identity Federation Workforce Identity Federation Who is it for? Internal Employees Machines and Software External Personnel Primary Use Case Full-time staff who need G-Suite, Gmail, Drive, and Google Cloud. AWS Lambda, GitHub Actions, On-premises servers needing Google Cloud&nbsp;access. Employees without Google Workspace Identities, Partners, Contractors, Vendors using their own IdP. Mechanism Synchronization (Users exist in Google). Token Exchange (No user creation). Token Exchange (No user creation). User Experience Login with Google. No UI (API and CLI only). Login using "Federated" Console or CLI.

### Text

Analogy
Let's take an example of the potential services that would be used for&nbsp;a hospital:

### Image

Cloud Identity is an employee badge. Workforce Identity is a visitor badge given because you showed your Driver's License (your external ID).

### Text

Summary
Now that you understand why you need Workforce Identity Federation to solve the GlobalTech challenge, you need to understand the mechanics. In the next lesson you&nbsp;will explore the Token Exchange Flow . You will trace exactly what happens to the data packets when an external user clicks "Login."

## The Architecture of Federation
*Type: blocks*

### Text

Learning objectives
By the end of this lesson, you will be able to:

### Image

✓&nbsp; &nbsp; Deconstruct the Token Exchange flow into its component steps. ✓&nbsp; &nbsp; Define the role of the Security Token Service (STS) in the Google Cloud IAM ecosystem. ✓ &nbsp;&nbsp; Distinguish between the Subject Token (Foreign Currency) and the Access Token (Local Currency).

### Text

The Concept: The Currency Exchange
In the previous lesson, you decided to let GlobalTech's partners bring their own identities. But Google Cloud doesn't translate to Okta natively, and Okta doesn't translate to "Google IAM" natively. They function with&nbsp;different languages and use different currencies. To bridge this gap, Workforce Identity Federation relies on a Security Token Service (STS).

### Text

Analogy
Imagine you are travelling to a foreign country. You have Dollars (your external identity), but the local vending machines only accept Euros (Google IAM permissions).

### List

You go to a Currency Exchange Booth (Google STS).

You prove your Dollars are real.

The booth gives you Euros.

You use the Euros to buy a snack.

### Text

Heading
In WIF, this process is technically known as Token Exchange.

### Text

The Actors (the cast of characters)
Before you review the workflow, let's define the pieces involved:

### Text

The Workflow: Tracing the packet
Let's trace exactly what happens when a PartnerCorp developer tries to log in.

### Text

Visualizing the Flow
Review the diagram below to cement the "Exchange" concept.

### Text

Deep dive: The "Trust" configuration
You might be asking: Why does Google STS trust the token in Step 4? This is established during the Configuration Phase (which you will learn about later). When you set up WIF, you perform a one-time exchange of secrets or public keys:

### List

If using OIDC : You tell Google the IdP's Issuer URL (for example&nbsp; https://dev-123.okta.com ). Google effectively "calls" that URL to ask for the public keys (JWKS).

If using SAML : You upload the IdP's Metadata XML to Google. This contains the public key needed to verify the IdP's signature.

### Text

Heading
If the Subject Token isn't signed by the private key corresponding to that public key, Google STS rejects the exchange immediately.

### Text

Summary
You now&nbsp;know how the exchange happens, but there are two main languages used for the "Subject Token": SAML and OIDC . In the next lesson, you will compare these two protocols. Which one should you choose for GlobalTech? Does it matter if your partner uses Active Directory or a custom web app? You will find out.

## Compare OIDC and SAML Protocols
*Type: blocks*

### Text

Learning Objectives
By the end of this lesson, you will be able to:

### Image

✓&nbsp; &nbsp; Compare the two primary protocols supported by Workforce Identity Federation: SAML 2.0 and OpenID Connect (OIDC). ✓&nbsp; &nbsp; Identify the data formats associated with each (XML and JSON). ✓ &nbsp;&nbsp; Select the appropriate protocol based on the capabilities of the external Identity Provider (IdP).

### Text

The Concept: Choosing the Language
In the previous lesson, you learned that the IdP sends a "Subject Token" to Google. But what format is that token in? To make Federation work, Google and the Partner must agree on a common language. Workforce Identity Federation is bilingual. It speaks:

### List

SAML 2.0 (The Enterprise Veteran)

OIDC (The Modern Standard)

### Text

Heading
In general OIDC is recommended as the modern standard, if the identity provider supports it. OIDC is generally preferred today because it eases key rotation and provides other convenient features. For example, if an Okta application rotates its signing keys, Google WIF can pick up the new public key automatically. With SAML, you might have an outage until you upload the new certificate. Additionally, suppose a user has a field updated within Okta, WIF integration using OIDC can provide these updated fields to Google IAM the next time the user logs in. If WIF integration uses SAML, the user may need to be removed and re-added to the Okta application for user field updates to be shared downstream to Google IAM during authentication.

### Text

Comparison
When we show up to the present moment with all of our senses, we invite the world to fill us with joy. The pains of the past are behind us. The future has yet to unfold. But the now is full of beauty simply waiting for our attention.

### Text

Feature SAML 2.0 OpenID Connect (OIDC) Data Structure XML (older format) JSON (newer standard) Trust Setup Uploading a Static XML Metadata file which contains a public key. Built on top of OAuth 2.0. Dynamically fetches keys from a dynamic "Discovery URL" ( .well-known ). How User Updates are Handled Users may need to be deleted and recreated in the Identity Provider application for updates on users (like a department change) to transfer. Updates to users should automatically transfer. Key Rotation Hard: If the Partner changes their certificate, you must manually upload the new one to Google. Easy: Google automatically checks the URL for new keys. Debugging You can debug in the browser directly using Chrome Developer Tools or a plugin. You need to intercept the token and paste it into a debugger (like jwt.io ) to read it. Industry Trend Stable / Declining Growing / Standard

### Text

The GlobalTech Decision
Back to the scenario. You are setting up the pool for PartnerCorp.

### Image

Partner : "We use Okta." You : "Great. We prefer OIDC because it automates certificate rotation, meaning less maintenance for us later. Here is our Redirect URI. Please provide your Issuer URL, Application (Client) ID, and Client Secret." Note: You will configure this specifically in Module 2.

### Text

Summary
Congratulations! You have completed this module on&nbsp;Foundations and Architecture. You learned that WIF allows you to trust external identities without creating Google accounts. You learned that WIF is essentially a Currency Exchange (STS) converting Subject Tokens to Access Tokens. You learned the difference between the XML-based SAML and the JSON-based OIDC. In the next module you open the Google Cloud Console. You will act as the administrator and build the infrastructure you have just learned about. You will start by creating the Workforce Identity Pool.

## Configuration and Implementation
*Type: section*

## Pools and Providers
*Type: blocks*

### Text

Learning objectives
By the end of this lesson, you will be able to:

### Image

✓&nbsp; &nbsp; Construct the logical hierarchy of Workforce Identity: Organization to Pool to Provider. ✓&nbsp; &nbsp; Create a Workforce Identity Pool using the Google Cloud Console. ✓ &nbsp;&nbsp; Apply naming conventions and session duration settings that balance security with user experience.

### Text

The Workforce Pool: the container
Before you click any buttons, you need to&nbsp;understand where these resources live.

### Text

Required Roles
You will require the IAM role of IAM Workforce Pool Admin , assigned at the organization level.

### Text

The Structure
When we show up to the present moment with all of our senses, we invite the world to fill us with joy. The pains of the past are behind us. The future has yet to unfold. But the now is full of beauty simply waiting for our attention.

### Text

The metaphor
If Google Cloud is a university campus consisting of many secured buildings: Each Pool is a building on campus (buildings with classrooms, the teaching hospital, the research labs, the dorms). Each Provider is a door into this pool. (Students have Student IDs, security officers have Security credentials, healthcare workers have their own credentials, and so on). Once they are in the building (Pool) people with certain attributes (for example, staff) can access the staff lounge regardless of which type of Badge (Provider) they used.

### Text

A Globally Unique ID
Workforce Pools are global resources, and therefore must have globally unique names across all customer organizations. The ID must be 4-32 characters, and may contain letters, numbers, and hyphens. The prefix gcp- is reserved for use by Google.

### Text

Step-by-Step: Creating the Pool
Let's apply this to the GlobalTech scenario. You need a place for your PartnerCorp developers to land.

### Text

You now have an empty Pool. It has no "Doors" (Providers) yet, so nobody can enter, but the structure exists.

### Text

Critical Concept: Multi-Provider Pools
You might ask: Why not just make a new pool for every partner? You can, but the power of the Pool is Aggregation . Imagine GlobalTech hires three different design agencies. They all use different IdPs (One uses Okta, one uses Ping, one uses Entra ID).

### List

You create one pool called creative-agencies .

You add three providers inside it.

You write one IAM Policy: "Allow members of creative-agencies to view the Design Storage Bucket."

### Text

Heading
If you had three different pools, you would have to write and maintain three different IAM policies. Group by function, not just by source .

### Text

Summary
You have built the "Lobby" ( partner-pool ). Now you need to unlock the door. In the next lesson, you will configure the Identity Provider (IdP) . Since you decided in Module 1 to use OIDC for Okta, you will focus on that integration. After that, you will touch on SAML for completeness.

## Connect an IdP (OIDC)
*Type: blocks*

### Text

Learning objectives
By the end of this lesson, you will be able to:

### Image

✓&nbsp; &nbsp; Configure an OIDC Provider to trust a modern identity source (Okta). ✓&nbsp; &nbsp; Differentiate between the Issuer URI (The Source) and the Client ID (The Audience). ✓ &nbsp;&nbsp; Diagnose the common "Issuer Mismatch" error caused by URL syntax nuances.

### Text

Back to the Scenario: The "PartnerCorp" Connection
You successfully created a pool in the previous lesson. Now let’s grant access to the 500 Developers from PartnerCorp . They use Okta . You have recommended that they connect with OpenID Connect (OIDC) . To set this up, you need to:

### List

Ensure you have created the Workforce Pool (shown in the previous lesson) and have its Workforce Pool ID .

Determine a Workforce Provider ID that you will use. The Provider ID can have lowercase letters, digits, or hyphens, and must be at least 4 characters long, for example partnercorp-devs-oidc

To configure this application, the Identity Provider owner will need you to provide a Redirect URL . With the two IDs described above, you can construct a URL in this format, which you can provide to the PartnerCorp Admin:

### Text

You, then ask them for a few specific strings of text:

### List

Issuer URL : The address of their Okta instance. For example: https://partnercorp.okta.com .

Client ID : The ID of the application they created for you in their Okta portal.

Client Secret : a client secret associated with that Client ID.

### Text

How OIDC "Trust" works (the invisible handshake)
Unlike SAML, where you manually upload a certificate, OIDC is dynamic.

### Image

You tell Google : "Trust tokens from https://partnercorp.okta.com " Google asks : "Okay, how do I verify their signature?" The Automation : Google silently adds /.well-known/openid-configuration to the end of that URL, makes a request, and downloads the public keys (JWKS) automatically. The Benefit : If PartnerCorp rotates their keys tomorrow, Google updates automatically, with zero downtime .

### Text

Step-by-step: configuring the Provider
Let's open the Google Cloud Console and finish the job.

### Text

Click the play button to watch the video.

### Text

Troubleshooting: the "Issuer mismatch"
The most common error in OIDC federation is trivial but frustrating.

### Text

Click each flashcard to learn more.

### Text

Summary
In the next lesson, you&nbsp;will configure a SAML Provider. You will discover that it involves a little more back-and-forth coordination than with OIDC.

## Connect an IdP (SAML)
*Type: blocks*

### Text

Learning objectives
By the end of this lesson, you will be able to:

### Image

✓&nbsp; &nbsp; Configure a SAML Provider within a Workforce Identity Pool. ✓&nbsp; &nbsp; Interpret the function of the IdP Metadata XML file. ✓ &nbsp;&nbsp; Identify the critical "Audience URI" requirement to prevent common "Audience Mismatch" errors.

### Text

The Sub-Scenario: "Legacy Corp"
While you are setting up the system for PartnerCorp (Okta), the legal team calls. GlobalTech has also acquired a small manufacturing firm called Legacy Corp .

### List

Their Tech : They use a legacy on-premises Active Directory Federation Services (ADFS) server.

The Constraint : They cannot use OIDC. They must use SAML .

Your Task : Add a second "Door" to your existing Pool to let these users in.

### Text

To initiate the configuration:
Ensure you have created the Workforce Pool and have the Workforce Pool ID. Determine a Workforce Provider ID that you will use. The Provider ID can have lowercase letters, digits, or hyphens, and must be at least 4 characters long. For example&nbsp; legacycorp-saml You use the IDs listed above to construct two URLS, which you provide to the Legacy Corp Identity Provider Admin:

### Text


An Assertion Consumer Service (ACS) URL, which will be in the form:

### Text

Heading
An Audience URI (SP Entity ID), which will be in the form:

### Text

Heading
You, then ask them for their IdP Metadata XML file, which you will upload.

### Text

Step-by-step: configuring the Provider
Let's open the Google Cloud Console and finish the job. Click the play button to watch the video.

### Text

The "Entity ID" Error
One specific setting often causes confusion: The Entity ID . In the XML : The file Legacy Corp sent you has an entityID="http://adfs.legacycorp.com/adfs/services/trust" In the Token: When the user logs in, the token says Issuer="http://adfs.legacycorp.com/adfs/services/trust" If these do not match exactly (case-sensitive), it fails. Scenario : Sometimes admins manually type the Entity ID in Google Console instead of uploading the XML. If they type https instead of http , or add a trailing slash / , the handshake breaks. Best Practice : Always upload the file. Don't type it manually.

### Text

Summary
Congratulations! You have completed the Configuration and Implementation module. You built the Pool (The Lobby). You configured Providers (The Doors) for both OIDC and SAML. You have the building (Pool), and you have the badges (SAML and OIDC providers). But when the users walk through the door, who are they? Right now, Google just encounters a messy string of characters like assertion.sub . You need to translate "User 123" into "Jane from Engineering." In the next lesson, you will explore how to do this by using&nbsp; Attribute Mapping .

## The Logic of Access
*Type: section*

## Attribute Mapping
*Type: blocks*

### Text

Learning objectives
By the end of this lesson, you will be able to:

### Image

✓&nbsp; &nbsp; Translate external Identity Provider (IdP) claims into the Google Cloud Common Expression Language (CEL) syntax. ✓ &nbsp;&nbsp; Differentiate between Google's built-in attributes ( google.* ) and custom attributes ( attribute.* ).

### Text

The Concept: The Universal Translator
In the previous module, you got Alice (PartnerCorp) logged in. But right now, to Google, Alice looks like a meaningless string of characters.

### List

Okta says : User: 00uxopt8eu42Ade2q697 | Job: Dev | Level: L4

Google IAM says : "I don't know what 'Job' or 'Level' means. I only speak 'Google'."

### Text

Heading
Attribute Mapping is the configuration where you teach Google how to read the Partner's ID badge. You are writing a dictionary that says: When they say 'Job', &nbsp;interpret that as 'Department'.

### Text

The Syntax: Left = Right
The grammar of mapping is strict but simple. It uses Common Expression Language (CEL) .

### Text

Heading
The Left Side (Target) : What Google calls the data. The Right Side (Source) : What the IdP sends (accessed via the keyword assertion ).

### Text

1. The Built-in Attributes
Google has three reserved "buckets" that you must or can fill.

### Text

Google Attribute Description Required? Typical Mapping google.subject The Who . The unique ID of the user. YES assertion.sub or assertion.oid google.display_name The Label . What shows up in the top-right of the console. No assertion.name or assertion.displayname google.groups The List . A list of group memberships. No assertion.groups

### Text

2. The Custom Attributes
This is where the magic happens. You can create your own buckets to hold data specific to your business logic, like "Cost Center," "Project ID," or "Clearance Level."

### Text

Custom Attribute Description Required? Typical Mapping attribute.department Department the user works in. No. Custom defined assertion.custom_job_role

### Text

The Process: Configuring the Map
Let's map Alice's identity for the GlobalTech scenario.

### Text

The data from Okta (the source):
When we show up to the present moment with all of our senses, we invite the world to fill us with joy. The pains of the past are behind us. The future has yet to unfold. But the now is full of beauty simply waiting for our attention.

### Text

Your mapping logic (the configuration):
When we show up to the present moment with all of our senses, we invite the world to fill us with joy. The pains of the past are behind us. The future has yet to unfold. But the now is full of beauty simply waiting for our attention.

### List

Map the Subject: Logic: You want to identify her by her email, not her cryptic ID. Code: google.subject = assertion.sub or assertion.oid

Map the Name: Logic: Make the UI look nice. Code: google.display_name = assertion.email

Map the Department (Custom): Logic: You need to know she is in Engineering to give her server access later. Code: attribute.department = assertion.custom_job_role

### Text

Heading
Crucial Step : Before you can map attribute.department , you must define it in the Pool settings. You cannot map to a bucket that doesn't exist.

### Text

Visualizing the transformation
Study this diagram to observe how the data changes form.

### Text

Okta User (Incoming) The Mapping Filter Google Principal (Outgoing) sub: "alice-123" Ignore (Dropped) email: "alice@partner.com" google.subject = assertion.email Principal ID : alice@partner.com custom_job_role: "eng" attribute.dept = assertion.custom_job_role Attribute : dept: eng location: "us-east" Ignore (Dropped)

### Text

Heading
Result : Google now recognizes a user named " alice@partner.com " who has a tag of " dept: eng ".

### Text

Advanced logic: CEL function
Sometimes the data from the IdP is messy. You can use CEL functions to clean it up during the mapping.

### Text

Scenario
Okta sends email: "alice@partnercorp.com" . You only want the username ( Alice ) to be the display name.

### Text

The Fix
When we show up to the present moment with all of our senses, we invite the world to fill us with joy. The pains of the past are behind us. The future has yet to unfold. But the now is full of beauty simply waiting for our attention.

### Text

Heading
This splits the string at the @ symbol and takes the first part (index 0). Result : google.display_name becomes Alice .

### Text

Summary
You have successfully translated Alice's "Job Role" into a Google "Attribute." But what if you want to block Alice entirely if she isn't in the "Engineering" department? You don't just want to label her; you want to gatekeep her. In the next lesson, you will use Attribute Conditions to create security guardrails that allow or reject users at the door based on their data.

## Attribute conditions (the guardrails)
*Type: blocks*

### Text

Learning objectives
By the end of this lesson, you will be able to:

### Image

✓&nbsp; &nbsp; Construct Boolean CEL expressions to enforce specific entry criteria for external users. ✓&nbsp; &nbsp; Analyze the security benefits of filtering users at the "Pool Entry" level versus the "IAM Policy" level. ✓ &nbsp;&nbsp; Troubleshoot common logic errors involving case sensitivity and missing claims.

### Text

The Concept: The Bouncer
Imagine your Workforce Pool is a construction job site.

### List

Authentication (IdP) : Checking the ID card to make sure it's real.

Attribute Mapping : Writing a name tag for the guest.

Attribute Condition : The Gatekeeper.

### Text

Heading
Even if the ID is real, and you can write a name tag, the Gatekeeper might say: "Sorry, you don’t have the safety certification to enter this job site." In technical terms, an Attribute Condition is a logic check that runs after the token is verified but before access is granted. If the condition evaluates to False , the login fails immediately.

### Text

The Syntax: Boolean logic
Unlike Attribute Mapping (which was Left = Right ), Attribute Conditions must result in a True/False answer. You continue to use CEL (Common Expression Language) , which includes:

### Text

Logical operators Description String manipulation operators Description == Equals .contains() For lists or substrings != Does not equal .matches() or == For equality && AND .startsWith() For matching the start of the string || OR .endsWith() For matching the end of the string .lowerAscii() To lowercase a string .upperAscii() To uppercase a string

### Text

The GlobalTech Scenario: Tightening the Perimeter
Let's review the PartnerCorp requirements again. Risk : PartnerCorp has 10,000 employees. You only want the 500 developers to access your pool. You don't want their Sales or HR teams cluttering your logs or potentially finding accidental access.

### Text

The Policy Requirements
When we show up to the present moment with all of our senses, we invite the world to fill us with joy. The pains of the past are behind us. The future has yet to unfold. But the now is full of beauty simply waiting for our attention.

### List

User must be from partnercorp.com (No personal Gmails).

User must be in the Engineering department.

User's email must be verified (A security best practice).

### Text

The CEL Condition
When we show up to the present moment with all of our senses, we invite the world to fill us with joy. The pains of the past are behind us. The future has yet to unfold. But the now is full of beauty simply waiting for our attention.

### Text

How it executes
When we show up to the present moment with all of our senses, we invite the world to fill us with joy. The pains of the past are behind us. The future has yet to unfold. But the now is full of beauty simply waiting for our attention.

### List

Alice (Dev) : True && True && True results in ACCESS GRANTED .

Bob (Sales) : True && False && True results in ACCESS DENIED .

Eve (Hacker with fake email) : True && True && False results in ACCESS DENIED .

### Text

Critical Thinking: Why filter here?
You might ask: "Why not just let everyone in, but only give IAM permissions to the Engineering group?" This is the principle of Defense in Depth .

### Text

Click each + button to expand the items and learn more.

### Text

Common Pitfalls


### Text

Click each tab to learn more.

### Text

Summary
You have successfully mapped Alice's attributes and verified she is allowed to enter the pool. But right now, she is standing in the lobby. She has no keys to the server room. If she tries to list a Storage Bucket, Google responds with "403 Forbidden." In the next lesson, you will perform the final step: IAM Policy Binding . You will connect your mapped attributes to actual Google Cloud Roles.

## IAM policy binding
*Type: blocks*

### Text

Learning objectives
By the end of this lesson, you will be able to:

### Image

✓&nbsp; &nbsp; Construct the specialized principalSet IAM string required to grant access to Federated users. ✓&nbsp; &nbsp; Differentiate between binding a policy to a specific Subject (one person) versus an Attribute (a group/category). ✓ &nbsp;&nbsp; Apply the Principle of Least Privilege by creating granular bindings based on custom attributes.

### Text

The Concept: The Visitor Badge
Alice has passed the IdP check. She passed the Attribute Condition check. She is now inside the Google Cloud ecosystem. However, by default, she has 0 permissions . She cannot access projects, list VMs, or read logs. In standard IAM, you grant roles to an email: roles/storage.viewer is granted to user:alice@gmail.com In Workforce Identity, you don't have an email address in the traditional sense. You have a Federated Principal . You need a new way to point to Alice.

### Text

The Syntax: The principal Protocols
Workforce Identity introduces two new types of IAM Members. You will paste these strings into the "Add Principal" box in the IAM console.

### Text

Click each tab to learn more.

### Text

Step-by-step: Security policy
Let's implement the security policy for your PartnerCorp Developers .

### Text

Click the play button to watch the video.

### Text

Best Practice: Abstract vs. Concrete
Why use principalSet (Attributes) instead of principal (Subjects)? Scalability .

### List

Scenario : PartnerCorp hires 50 new engineers next week.

If using Subjects : You must manually edit the IAM policy 50 times to add every new ID.

If using Attributes : You do nothing . As long as their IdP sends department: engineering , they automatically inherit the Log Viewer role.

### Text

The Golden Rule : Use Attributes for Roles (RBAC). Use Subjects only when exceptions are required.

### Text

Troubleshooting
Click each + button to expand the items and learn more.

### Text

Summary
Congratulations! You have completed The Logic of Access module. You used Attribute Mapping to translate "Foreign Claims" into "Google Attributes." You used Attribute Conditions to act as a bouncer, rejecting invalid users. You used IAM Policy Binding to link attributes to permissions. The system is now fully functional. But what happens when things break? In the next module, you will explore Access and Troubleshooting , focusing on usage for developers and debugging logs for administrators.

## Operations, Security, and Troubleshooting
*Type: section*

## Access the console
*Type: blocks*

### Text

Learning objectives
By the end of this lesson, you will be able to:

### Image

✓&nbsp; &nbsp; Locate the specific "Federated Sign in URL" required for external users. ✓&nbsp; &nbsp; Explain the user journey from the initial click to the Google Cloud Console. ✓ &nbsp;&nbsp; Configure the necessary "Redirect URIs" in the external IdP to allow the browser to return to Google safely.

### Text

Problem and solution
First let's find out about the problem at PartnerCorp and how it can be resolved.

### Text

Click each tab to learn more.

### Text

The User Journey: A Simulation
Let's walk through what Alice, the PartnerCorp developer, experiences when she clicks that link.

### Text

Click each + &nbsp;button to expand the items and learn more.

### Text

Configuration Detail: The Redirect URI
There is one technical "plumbing" step required to make Step 4 work. When Okta sends Alice back to Google, it sends her to a specific "Callback URL."&nbsp;You provided this to the Identity Provider Admin previously: For OIDC : This was the Redirect URL you provided. For SAML : This was called the Assertion Consumer Service (ACS) URL. The Standard Callback URL : https://auth.cloud.google/signin-callback/locations/global/workforcePools/<POOL_ID>/providers/<PROVIDER_ID> The "Gotcha" : If the Identity Provider Admin hasn’t entered this URL into the Partner's IdP configuration, Alice will log in successfully to Okta, but then hit an error: "Redirect URI mismatch." She will be stuck on the Okta page and never get back to the Google Cloud Console.

### Text

Best Practice: Handling Multiple Providers
Remember the Partner Corp (OIDC) and Legacy Corp (SAML) scenario? They are in the same pool. If you send a link that only specifies the Pool (and not the specific provider), Google will show a "Select Provider" screen. Alice clicks the link. She encounters a menu: Button 1: Partner Corp (OIDC) Button 2: Legacy Corp (SAML) She must know which one to click. Recommendation : Always provide users the full link that includes the &provider= parameter to save your users confusion.

### Text

Summary
You have Alice using the Console. But she also wants to be able to run commands via gcloud. In the next lesson, you will enable access via the command line and APIs .

## CLI and API access
*Type: blocks*

### Text

Learning objectives
By the end of this lesson, you will be able to:

### Image

✓&nbsp; &nbsp; Explain how the gcloud CLI authenticates using Workforce Identity Federation (WIF) without a browser. ✓&nbsp; &nbsp; Generate the configuration.json file required for headless authentication. ✓ &nbsp;&nbsp; Execute a login command that utilizes external credentials instead of a standard Google user account.

### Text

Scenario: The Headless Runner
Alice (your PartnerCorp Lead) is happy with the Console access. But now she asks: "I have a Python script that uploads huge datasets to Cloud Storage. I run it from my laptop terminal. How do I authenticate? I don't have a Service Account key." If Alice tries gcloud auth login , it pops up a browser asking for a Gmail address. She doesn't have one. You need to teach the gcloud tool how to speak Workforce Identity .

### Text

The Key Component: The Configuration File
Unlike a standard user who just types their email, a WIF user needs a "map" that tells the CLI where to go (the Issuer URL, the Client ID, the Pool ID). This map is a JSON file. You (The Admin) must generate this file for your users.

### Text

Step 1: Generate the Config
You can create this file using the CLI:

### Text

The created file will be used to give gcloud the information it needs to use this Workforce Pool and Provider. It looks like this:

### Text

Heading
Breakdown of the command : create-login-config : The magic command. The Long String: The full resource path to the Provider (not just the Pool). --output-file : Where to save the JSON "map."

### Text

Step 2: Distribute the File
You email this login-config.json file to Alice. It contains no secrets—only configuration data (URLs and IDs). It is safe to share internally.

### Text

The User Experience: Logging In
Now, switching roles to Alice on her laptop. She saves the file to her home directory. To log in, she runs:

### Text

What happens next?
When we show up to the present moment with all of our senses, we invite the world to fill us with joy. The pains of the past are behind us. The future has yet to unfold. But the now is full of beauty simply waiting for our attention.

### List

The CLI reads the file.

It identifies that this is an OIDC provider.

It opens a browser window to Okta (not Google).

Alice logs in to Okta.

Okta passes the token back to the local CLI.

gcloud exchanges it for a Google Access Token.

### Text

Result
Alice receives:

### Text

Heading
She can now set a project and then run commands like gsutil cp huge-file.dat gs://my-bucket successfully.

### Text

Advanced: Headless / CI/CD Mode
What if Alice wants to run this on a Jenkins server or GitHub Action where there is no browser to pop up? Workforce Identity supports Headless flows, but it requires the environment to have a recent file-based OIDC credential (like a generic OIDC token saved to disk). You can read more about this in the Documentation for a given provider, for example the documentation covering sign-in methods for Okta . Note : This is an advanced topic, but it's important to know that Workload Identity Federation (not Workforce Identity Federation) is the standard way to auth GitHub Actions to Google Cloud (via Workload Identity).

### Text

Summary
You have Alice using the Console and the CLI. But suddenly, at 3:00 PM, she gets an "Access Denied" error. She calls you. "I didn't change anything!" How do you investigate? In the next lesson, you become Detectives. You will dive into Cloud Logging to trace the failures in the authentication handshake.

## Investigate Logs
*Type: blocks*

### Text

Learning objectives
By the end of this lesson, you will be able to:

### Image

✓&nbsp; &nbsp; Construct Cloud Logging queries to isolate Workforce Identity events. ✓&nbsp; &nbsp; Distinguish between a Token Exchange Failure (STS) and an IAM Authorization Failure (Permission). ✓ &nbsp;&nbsp; Locate the specific logic error when an Attribute Condition denies access.

### Text

The Concept: The Black Box Recorder
Alice calls you: "I tried to log in, and it just says 'Error: Authentication Failed'. Help!" The UI error message is intentionally vague for security reasons. To fix it, you need to view the Cloud Audit Logs. There are two distinct systems you must audit, depending on when the error occurred:

### List

STS (Security Token Service) : The "Front Door." Errors here mean the login failed.

IAM (Identity & Access Management) : The "Room Key." Errors here mean the login worked, but the user touched something they shouldn't.

### Text

Step-by-step: Fixing the Token Exchange
If the user cannot get to the Console at all, the issue is in the Token Exchange.

### Text

Click the play button to watch the video.

### Text

Troubleshooting
When we show up to the present moment with all of our senses, we invite the world to fill us with joy. The pains of the past are behind us. The future has yet to unfold. But the now is full of beauty simply waiting for our attention.

### Text

Click each tab to learn more.

### Text

The "Mapped Attributes" View
A hidden gem in Cloud Logging is viewing what attributes were actually mapped during the login. In the STS logs of a successful login (protoPayload.methodName: “SignIn”) , check for protoPayload.metadata.mappedAttributes . It contains a JSON dump of the data the IdP sent.

### List

Scenario : Alice swore she was an "Engineer."

The Log : The log proves Okta sent her role as "Intern."

Resolution : The problem isn't in Google. Alice needs to talk to her HR/IT department to update her Okta profile.

### Text

Summary
You have fixed the errors. Alice is logged in, her attributes are correct, and she can access the bucket. In the next lesson, you will cover SCIM support for Gemini Enterprise .

## WIF for Gemini Enterprise
*Type: section*

## Grant federated users access to Gemini Enterprise
*Type: blocks*

### Text

Learning objectives
By the end of this lesson, you will be able to:

### Image

✓&nbsp; &nbsp; Provide third-party users access to Gemini Enterprise ✓&nbsp; &nbsp; Configure your AI Applications identity provider to use a workforce pool ✓ &nbsp;&nbsp;Configure integrations with your Gemini Enterprise app

### Text

Summary
You have now granted third-party federated users access to Gemini Enterprise, by configuring an integration between AI Applications and your Gemini Enterprise app using your workforce pool.

## SCIM support for Gemini Enterprise
*Type: blocks*

### Text

Learning objectives
By the end of this lesson, you will be able to:

### Image

✓&nbsp; &nbsp; Enable SCIM for Gemini Enterprise deployments

### Text

The Scenario: Sharing NotebookLM notebooks
If your IdP supports System for Cross-domain Identity Management (SCIM) , adding a SCIM tenant in your IdP application allows Gemini Enterprise users to share NotebookLM notebooks with a group using the group's name instead of its object ID (UUID). To learn more about sharing notebooks with groups, visit:&nbsp; Share a notebooks with a group . Before creating a SCIM tenant, be sure to familiarize yourself with the limitations documented in the SCIM support documentation.

### Text

One important fact to understand is that you can only have one SCIM tenant in an organization, and if you delete a tenant without using the --hard-delete flag, you will initiate a 30-day soft-delete period. During this time, the tenant is hidden and cannot be used, and you cannot create a new SCIM tenant in the same workforce identity pool.

### Text

Heading
Specific instructions for enabling SCIM with Microsoft Entra ID are provided in the documentation Configure SCIM for Microsoft Entra ID . For other providers, refer to Configure SCIM for Other OIDC / SAML providers .

## summary
*Type: section*

## Course summary
*Type: blocks*

### Text

Congratulations! You have completed the course Use a Third-Party Identity Provider with Workforce Identity Federation . You have moved from understanding the basic problem (Shadow IT) to architecting a complex, attribute-based access control system using modern Identity standards.

### Image

✓ &nbsp;&nbsp; Describe the architecture and token exchange flow of Workforce Identity Federation (WIF). ✓&nbsp; &nbsp; Configure Identity Pools and Providers for both SAML 2.0 and OIDC. ✓ &nbsp;&nbsp; Implement attribute mapping and write CEL logic for access conditions. ✓ &nbsp;&nbsp; Bind IAM policies to federated identities. ✓ &nbsp;&nbsp; Utilize CLI/API access and investigate authentication logs.
