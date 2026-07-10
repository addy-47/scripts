# Model Armor: Securing AI Deployments

## Course Overview
*Type: section*

## What's in it for me?
*Type: blocks*

### Image

If you're here, it means you've got something precious to protect. And no, for all you Lord of the Rings fans, we're not talking about a tiny, shiny, soul-corrupting ring. We're talking about something even more valuable to your organization: your Large Language Model (LLM) and the associated data. Your organization invested lots of time, money, and resources to create an LLM. It's the brains behind the AI strategy that's helping you achieve new and exciting things. Here's the kicker: like any powerful asset, it's also a tempting target.

### Text

Your challenge
From prompt injection to data poisoning, the ways an LLM can be compromised are enough to give any security professional a serious case of the jitters. It's hard to believe, but some of these risks even made a "Top 10" list, which is both impressive and terrifying. You don't have to face these digital battles alone. You have Model Armor. And in this training, we're going to show you exactly how to wield it. Consider this your crash course in becoming an LLM superhero.

### Text

Here's a short video clip that explains why you'll want to know more about Model Armor.

### Text

After this course, you'll be able to...
When we show up to the present moment with all of our senses, we invite the world to fill us with joy. The pains of the past are behind us. The future has yet to unfold. But the now is full of beauty simply waiting for our attention.

### Image

Explain the purpose of Model Armor in a company's security portfolio. Define protections that Model Armor applies to all interactions with the LLM. Set up the Model Armor API and know where to see violations. Identify how Model&nbsp;Armor manages prompts and responses.

## Model Armor Overview
*Type: section*

## About Model Armor
*Type: blocks*

### Text

Heading
What is Model Armor you ask? Check out&nbsp;these videos for a quick introduction.

### Text

Model Armor Introduction
Think of this like a handshake. Here's your brief introduction to the service.

### Text

Key features overview
You've met Model Armor. Now it's time for a more thorough introduction. Let's watch a short demo that shows Model Armor in action.

## LLM security risks
*Type: blocks*

### Text

LLM Security Vulnerabilities
Who doesn't love a good top 10 list? We have them for everything from sports and entertainment to business and daily life. LLM security is no different. You may be wondering if there's a top 10 list for LLM security risks? And the answer is yes!

### Text

OWASP top 10 LLM vulnerabilities
This official Top 10 list of LLM vulnerabilities comes courtesy of the Open Worldwide Application Security Project (OWASP) Foundation . They're the pros, who in partnership with security experts from around the globe, exist to make software security better. Good news: Model Armor takes out&nbsp;four of these major threats! Let's check out what Model Armor is guarding against.

### Image

Malicious files and unsafe URLs It's common knowledge&nbsp;that attackers can hijack your LLM by embedding malicious URLs in a prompt. The LLM unwittingly follows the URLs without questioning the intent. Even PDFs can become Trojan horses for unsafe URLs. The big question is how do you prevent this from happening? Model Armor's PDF Screening and Malicious URL detection automatically detects and deflects these hidden threats, so you're always covered.

### Image

Prompt injection and jailbreaks What we're talking about here&nbsp;are creative methods&nbsp;to circumvent safety protections and manipulate LLM behavior. Model Armor is a master at spotting these tricks. Its Prompt Injection and Jailbreak detection is specifically built to catch attempts to bypass security and stop digital troublemakers in their tracks.

### Image

Sensitive data Remember that special kind of torture when your credit card gets compromised and you're stuck updating all your automatic payments? Nobody wants that headache. In the same way, customers expect LLMs to keep Personally Identifiable Information (PII) and other sensitive data secure. That's where Model Armor saves the day! Its Data Loss Prevention (DLP) using Sensitive Data Protection comes with a pre-defined set of basic information types (infoTypes). These infoTypes are designed to find PII, transform it, and keep private details far from prying eyes.

### Image

Offensive material In business, reputation is one of your most valuable resources. Allowing someone to hijack your LLM to post offensive material could damage that reputation. Your LLM is nobody's playground. Enter Model Armor with its Safety and responsible AI&nbsp;filters . These settings allow you to configure strict boundaries, ensuring no unsavory data goes in or out of your LLM.

### Text

Check out this video to learn more about prompt injection and what Model Armor can do to combat it.

### Text

Test your knowledge
Let's review what you've learned so far. Read the LLM vulnerability on the front of each card and then flip the card to reveal the Model Armor feature that prevents it.

### Text

Click each flashcard to learn more. Then click the arrows to navigate to the next or previous card.

## Customize Model Armor
*Type: section*

## About customization
*Type: blocks*

### Image

"One size fits all?" Pfft. That's a fantasy for both t-shirts and top-tier security. Your organization has its own specific, often quirky, LLM safety requirements. There's no cookie-cutter solution for something this important. That's why Model Armor is designed to be totally flexible. You can tweak&nbsp;and customize the service to match your unique security needs. Consider it your LLM's bespoke security solution.

### Text

Making it personal
How does Model Armor offer such tailored protection? Through two core features: floor settings and templates .

### Text

Click each tab to learn more.

### Text

Heading
Ready to see how these features work their magic? Let's explore!

## Floor settings
*Type: blocks*

### Image

What's the first&nbsp;step in truly customizing Model Armor? Floor settings . And no, we're not talking about redecorating. These settings are the non-negotiable, baseline requirements that every template must follow. You need consistent protection across all your AI applications. These rules establish the absolute starting point for templates, making it easier for your security pros to maintain a unified front.

### Text

Configuration
Let's start with the golden rule of floor settings: Always create floor settings before you define templates .

### Image

Think of it this way: you wouldn't build the walls of your house before pouring the foundation, right? Following this order ensures your templates play by the rules, adhering to the baseline requirements identified in floor settings.

### Text

Want to know your options? You can configure floor settings at three levels in your resource hierarchy.

### Text

Click each button to expand the three items and learn more.

### Text

Check out this video to learn more about floor settings.

### Text

Considerations
Before you decide where to create the floor settings, think about three things:

### List

What level is best? Creating at the organization level means that all folders and projects in the organization can inherit those requirements. This makes sense if you want sweeping baseline requirements for everything . Or, you can create them at the folder level or project level and create more specific settings that apply only to projects in that folder or project, respectively.

What minimum requirements do I want all templates at that level to follow? Spend a few minutes thinking about those minimum requirements. Templates layer on additional protections, so make your floor settings strategic.

Do I want to customize? Do you have a special project or folder that absolutely must have a more relaxed template? With the right permissions, an administrator can break the inheritance to create a custom template or even disable the floor setting requirement altogether.

### Text

Interested in learning&nbsp;more? Check out the floor settings content in the Help Center article titled,&nbsp;" Model Armor floor settings" .

### Text

Test your knowledge
How well do you know floor settings?&nbsp;Read the statement on the front of the card and then flip it to see if you know the right answer.

### Text

Click each flashcard to learn more. Then click the arrows to navigate to the next or previous card.

## Guard rails and confidence levels
*Type: blocks*

### Text

Floor settings prevent individual developers from accidentally - or intentionally - lowering security standards below acceptable levels. So, what happens if someone ignores a floor setting? Let's take a closer look.

### Image

Imagine this: a security expert lays down the law with a floor setting. Then, a cloud security engineer, perhaps a little too caffeinated, tries to create a template with a confidence level that's less strict than the floor&nbsp;setting minimum. What happens next? Model Armor doesn't just politely suggest a change; it throws up an error message and refuses to create or update&nbsp;the template. Model Armor simply says, "Nope! Not gonna happen."

### Image

Here's some more great news. Templates trying to meander around floor settings aren't just blocked, they are captured and surfaced in Logs Explorer. It's easy to spot and fix templates that aren't following the rules.

### Text

Teaching Model Armor to trust its gut
Here's another neat trick you can pull with floor settings: you can give Model Armor sensitivity instructions, also known as a confidence level . Basically, you're telling Model Amor, "Hey, when you spot something shady, you need to be this sure before you flag it as a violation." You're setting its digital "gut feeling" level.

### Image

Think of this as a balancing challenge. On one side, you're trying to snag all the real bad guys, or the true positives . &nbsp;On the other side, you're desperately trying to avoid flagging your grandma's recipe for banana bread as a security threat, a false positive . &nbsp;That's why a medium confidence level is usually your best bet to start things off. Let's look at each level in a bit more detail.

## Templates
*Type: blocks*

### Image

Alright, let's talk about templates. Think of these as your LLM's personal body guard, standing firm at the velvet rope. These aren't just basic floor settings: we're dealing with the VIP security detail. Templates tell the API what trouble to flag. When that trouble is identified, it's logged as a violation. Time to decide what gets to access your LLM and what is screened and left out in the cold.

### Text

Template Configuration
There are three main parts to a template: general info , detections and responsible AI . This is where the magic happens. You tell Model Armor what you are concerned about and it takes care of the rest. You can create templates using the Model Armor API or you can use the Model Armor page in Security Command Center. In our examples, we'll create templates from the Model Armor page.

### Text

Click on the five&nbsp;tabs to learn more.

### Text

Check out the video below to watch template creation in action.

### Text

Test your knowledge

### Text

Let's check what you've learned about templates. Explore the cards below to see how much you know.

### Text

Click each flashcard to learn more.

## Use Model Armor
*Type: section*

## About setup
*Type: blocks*

### Image

We got a little ahead of ourselves, didn’t we? We’ve been treating Model Armor like it’s an exciting new book series. We dove right into the plot, namely customization, and &nbsp;completely skipped the prologue, the setup. &nbsp; Time to play catch up. You&nbsp;can’t be a security pro if you don’t know how to get Model Armor started. Let’s hit rewind and cover setup basics.

### Text

Enablement Options

### Text

With Model Armor, you always have choices. You can indulge your developer side and work strictly in the API. &nbsp;Or, if you prefer to click buttons and let things happen auto- magically , you can&nbsp;enable the API from the Google Cloud console&nbsp;and start there.

### List

Enable Model Armor from the API. We'll talk about&nbsp;this in a separate lesson so that we cover&nbsp;all of the API setup details.

Enable Model Armor from the Google Cloud console . Here's a quick way to get started. Just navigate to the Model Armor page in Security Command Center and click the button to enable the API. You're ready to start creating templates and floor settings right from the UI.

### Text

Want to know more about API setup? Let's explore!

## API setup
*Type: blocks*

### Image

So, you might be dreading a wordy explanation of APIs and how to work with them. No worries! We're not doing that. Short and sweet: here are&nbsp;all the things you need in order to start working with the API.

### Text

Click each button to expand the five items and learn more.

## Flagged violations
*Type: blocks*

### Image

If we stay with our book analogy, now we're jumping to the conclusion. Time to see the way the story ends. At this point, you know what Model Armor can do and how to enable&nbsp;it. Floor settings are a breeze and you've got the template thing down.&nbsp;Wouldn't it be nice to know what happens when Model Armor starts screening based on your requirements? Then let's get to it. Here's how you find those&nbsp;flagged violations.

### Text

Logs
Model Armor is a multi-tasker. It's screening the text&nbsp;going in and out of the LLM and it's also taking notes on the activities. These notes are surfaced to you in the form of logs. There are two types of logs: Admin activity&nbsp;audit logs and Data access logs . Logs are enabled in the template when you're working in the API. To make things easy, bookmark the Help Center article titled, " Model Armor audit and platform logging" .

### List

Admin Activity audit logs capture details about template, floor setting, and basic computing (CRUD)&nbsp;operations.

Data access audit logs capture details about screening operations. For example, what template was used to screen a prompt or response, what was the text, and what was the result?

### Text

Cut through the noise with Logs Explorer .

### Text

Logs Explorer
There's a lot going on in Logs Explorer. You need to cut through the noise and find exactly what you want - those Model Armor logs. From the Google Cloud console, choose Monitoring and then select Logs Explorer. Here are a few&nbsp;filters that are useful for targeting Model Armor logs.

### Text

Click each button to expand the two items and learn more.

### Text

Log Examples
Seeing is believing. Let's take a look at an example from both types of logs.

### Text

Admin activity audit log example
This log example shows what's captured when a new template is created. Here are some things to notice.

### Text

Click each button to expand the three items and learn more.

### Text

The rest of the log file shows what was configured in the template.

### Text

Data access log example
This log example shows what's captured when a user prompt is screened. You want to watch for matchState with MATCH_FOUND . That's how you know that a violation was discovered. Here are a few examples.

### Text

Click each button to expand the two items and learn more.

### Text

Almost done! Now let's play around with Model Armor and get some hands-on experience with the service.

## Put it all Together
*Type: section*

## Prompts and responses
*Type: blocks*

### Text

The best way to understand something new is to take time to play with it. This is your opportunity to really see what Model Armor can do. Watch this video on screening prompts and responses. Then, try out the self-paced lab that ties together everything you've learned in this training.

### Text

Self-paced lab
Try it out! Use this lab to practice what you've learned about Model Armor.

## Application code
*Type: blocks*

### Text

Model Armor's job is done. Now it's your turn.

### Image

Time to pass the baton. Model Armor's job is done. It took your minimum requirements, applied your templates, and identified the bad actors. Now it's time for you to take over. You need to decide how to resolve the issues that it discovered.

### Text

Make a plan
Not sure what to do now that it's all back to you? Let's lay it out. When using the Model Armor REST API, you can write application code to perform a few simple steps.&nbsp;

### List

Make a call . Call Model Armor to screen user prompts and model responses.

Read responses . Parse Model Armor's responses after each completed call.

Decide what to do . Think about the best way to respond to what Model Armor provided. You have a few choices: Block the user's request. Block the model's response. Warn the user. Use redacted text and continue your workflow.

### Text

Want a little bit more? Here's a simple Python example that includes each of the application code steps, from calling Model Armor to deciding what to do next. &nbsp;

## Course Conclusion
*Type: section*

## What did I learn?
*Type: blocks*

### Image

Amazing job! We hope you enjoyed traveling with us through this course. You've completed all the modules and are now on your way to LLM superhero status. Take a minute to bask in the light of what you learned in this training. You can do all of these things: ✓&nbsp; &nbsp; Explain the purpose of Model Armor in a company's security portfolio. ✓&nbsp; &nbsp; Define protections that Model Armor applies to all interactions with the LLM. ✓ &nbsp;&nbsp; Set up Model Armor API and find violations. ✓ &nbsp;&nbsp; Identify how Model Armor manages prompts and responses.

### Text

Now...go protect those LLMs!
