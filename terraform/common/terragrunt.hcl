include "root" {
  path = find_in_parent_folders()
}

inputs = {
  infisical_org_id = get_env("INFISICAL_ORG_ID", "")
}
