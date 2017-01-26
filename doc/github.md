## Using this repository and Github

To get started
- create an account on github, preferably using your full name in the account name
- fork this repository to your accont on github
- login on a (linux) computer and make a local clone of your repository with “git clone git@github.com:username/meg-pipeline.git”, this is the origin
- configure the shared repository as the upstream remote “git remote add upstream git@github.com:Donders-Institute/meg-pipeline.git”

Whenever you want to update your copy with the changes made by your colleagues at the Donders, you would do
- “git pull upstream master” to get the updates
- “git push upstream master” to copy them to your github account

Whenever you want to make changes to your version and contribute them to your colleagues at the Donders, you would do
- “git checkout master” to ensure you are on the master branch
- “git checkout -b yourbranch” to make a new branch
- implement the changes
- “git push origin yourbranch” to copy your changes to your repository on github
- go to the github website to create a pull request, which can be reviewed and manually merged into the shared version


