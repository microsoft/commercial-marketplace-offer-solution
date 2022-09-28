# Contributing to Code Repostiry

When users want to update the repostiory they should make new Pull Requests targeting the 'main' branch.
This will automatically trigger GitHubs configured for the repository.
The GitHub actions will run static analysis checks on the ARM template, deploy the ARM template, and test publishing the solution.
Once a PR is completed, and the code is commited to 'main', a "Preview" release is automatically triggered.
See [here](./RELEASE.md) for more details. 
