# Setup GitHub Repo

After creating a new repo from the [template](https://github.com/microsoft/commercial-marketplace-offer-solution), we recommend making the following configurations to your new repository.

## Settings
### General
In Pull Requests: 
- set "Allow squash merging" to "Default to pull request title and description"
- Enable "Always suggest updating pull request branches"
- Enable 'Allow auto-merge'
- Enable 'Automatically delete head branches'

### Environments
Create 3 new environments, "Development", "Preview" and "Public". Set the 'deployment branches' for 'Preview' and 'Public' to 'main'.

Create a new secret 'AZURE_CREDENTIALS' in each env using the output of `az ad sp create-for-rbac -n "github-charybdis" --sdk-auth`. 
A unique SP must be created for each publisher account. If using one publisher account, it is recommended to use a different SP for "Public".
The SP in the Public env must be set to a "manager" in the Marketplace publisher account. The other SPs can be set as developers.

### Branches
Create a new "Branch Protection rule" for the 'main' branch.
In the Branch Protection rule:
- Set 'Require a pull request before merging
- Set 'Require approvals' to >= 1
- Set 'Require status checks to pass before merging' and add ValidateARMTemplates, PublishDraftOffer and DeployTemplate
- Set 'Require conversation resolution before merging'
- Set 'Require deployments to succeed before merging' and select 'Development'
- Set 'Do not allow bypassing the above settings' (Admins should unset/set this only as needed)

### Codespaces
- Set up prebuild from 'main' on configuration changes.

### Actions
- Set 'Allow all actions and reusable workflows'
- Unset 'Send secrets to workflows from fork pull requests.'

### Code security and analysis
Enable each of the following settings.
- Dependency graph
- Dependabot alerts
- Dependabot version updates
- Secret scanning
- Push protection
