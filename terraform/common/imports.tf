# Import existing Infisical resources. Remove after successful import.

# Folders
import {
  to = infisical_secret_folder.root["terraform"]
  id = "bcdf62bd-5bad-4b8b-b19f-97f4bf386c86"
}
import {
  to = infisical_secret_folder.root["generated"]
  id = "65ac7f4c-d2a6-40c1-b8e9-156375496b14"
}
import {
  to = infisical_secret_folder.sub["env"]
  id = "d037d2a7-ec46-4930-888f-1e9a816bc744"
}
import {
  to = infisical_secret_folder.sub["vars"]
  id = "928d50a5-5d39-4c63-b2f6-180d7908190e"
}

# Secrets: /terraform/env
import {
  to = infisical_secret.user_managed["GITHUB_PAT"]
  id = "5dab1950-e006-4e73-af1e-5bf03416c5b0"
}
import {
  to = infisical_secret.user_managed["TF_API_TOKEN"]
  id = "582a8d19-0898-4842-8f80-a0e29f9502c7"
}
import {
  to = infisical_secret.user_managed["TF_CLOUD_ORGANIZATION"]
  id = "d0e73485-1279-4874-86f6-665109ce7f5f"
}
import {
  to = infisical_secret.user_managed["NEW_RELIC_API_KEY"]
  id = "877c690a-840d-4fb7-80b7-e267121f5844"
}
import {
  to = infisical_secret.user_managed["NEW_RELIC_ACCOUNT_ID"]
  id = "74a984a3-9803-4619-a866-b5b7c7e21225"
}
import {
  to = infisical_secret.user_managed["NPM_TOKEN"]
  id = "88576ffe-bdf4-4ce2-a1f9-fc04ffd9ab15"
}
import {
  to = infisical_secret.user_managed["INFISICAL_UNIVERSAL_AUTH_CLIENT_ID"]
  id = "db9aa594-0411-42da-bce1-c23a5fdf7ea5"
}
import {
  to = infisical_secret.user_managed["INFISICAL_UNIVERSAL_AUTH_CLIENT_SECRET"]
  id = "ccb1fc83-7f6d-4079-a3d7-77cbc6d92ac8"
}

# Secrets: /terraform/vars
import {
  to = infisical_secret.user_managed["infisical_project_id"]
  id = "62e8a899-65a5-424e-88f9-60d54a4ccec4"
}
import {
  to = infisical_secret.user_managed["environment_slug"]
  id = "4a7212fc-bf3d-4d4e-afb6-618dce34f1cd"
}
