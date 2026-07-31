# Copyright 2025 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

""" 
This script is intended to assist with the construction 
and HTML-encoding of the Authorization URI described in the
documentation entitled 'Add an authorization resource to Gemini
Enterprise' found here:
https://docs.cloud.google.com/gemini/enterprise/docs/register-and-manage-an-adk-agent#add-authorization-resource
"""

# 1. Replace with your OAuth Client's Client ID
OAUTH_CLIENT_ID = "773019244907-gq9iqbkrkmggqq178nsvnguau0s4t083.apps.googleusercontent.com"

# 2. Add any Google API scopes that your app needs, for example:
SCOPES = ["https://www.googleapis.com/auth/userinfo.profile", "https://www.googleapis.com/auth/userinfo.email"]

# These should remain unchanged
REDIRECT_URI = "https://vertexaisearch.cloud.google.com/static/oauth/oauth.html"
OTHER_REQUIRED_QUERY_PARAMETERS = "include_granted_scopes=true&response_type=code&access_type=offline&prompt=consent"

import urllib.parse
encoded_redirect = urllib.parse.quote(REDIRECT_URI, safe="")

query_parameters = [
    "access_type=offline",
    f"client_id={OAUTH_CLIENT_ID}",
    f"redirect_uri={encoded_redirect}",
    "include_granted_scopes=true&response_type=code&prompt=consent"
]
if SCOPES:
    scopes_substring = f"scope={'%20'.join(SCOPES)}"
    query_parameters.append(scopes_substring)

# HTML Encoding
query_parameters_joined = "&".join(query_parameters)
query_parameters_to_html_encoding = query_parameters_joined \
    .replace(" ", "%20") \
    .replace(":", "%3A") \
    .replace("/", "%2F")

# Constructing the Auth URI
auth_uri = "https://accounts.google.com/o/oauth2/v2/auth?" + query_parameters_to_html_encoding

# Printing it to include in your authorization:
print("Auth URI: \n\n" + auth_uri + "\n\n")
