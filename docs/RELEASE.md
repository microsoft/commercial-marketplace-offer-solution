# Publish and Release App To Azure Marketplace

This repostiory is configured with GitHub Actions that automate the publication and release of Marketplace Applications.

After completing a Pull Request, a GitHub Action updates the marketplace offering, and triggers the publication to Preview.
It can take up to an hour for a new application preview to become avaiable, but should be faster for future submissions.

Once the Application is in Preview, to promote it to live, create a new GitHub release.
This will trigger another GitHub action to release the application.
After release, the application will not be immediately ready.
The submission will first be reviewed by the Marketplace and could take several days.
Additional submissions can not be made while an App is in review.
