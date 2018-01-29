Refuge Restrooms for iOS - Contributors Guide
============================================

#### Getting Started

* If there isn't an Issue filed for what you're working on, first [create a new Issue](https://github.com/RefugeRestrooms/refuge-ios/issues/new)
* Fork and clone the repository
* Change to the `refuge-ios/refuge-ios` directory and install required Cocoapods by running `pod install`
* Create a branch specific to the work you're going to do See: [Branch Naming Conventions](#branch-naming-conventions)
* When finished with changes, create a Pull Request against the `develop` branch of the repository

#### What to Work On

Check out the [list of open issues](https://github.com/RefugeRestrooms/refuge-ios/issues) for ideas of what to work on. This includes [non-technical issues](https://github.com/RefugeRestrooms/refuge-ios/labels/non-technical) issues for those wishing to contribute without coding.

The most pressing issues can be found in the [most current milestone](https://github.com/RefugeRestrooms/refuge-ios/milestones) that does not end in `x`. i.e. If there is a milestone named `Launch v1.1.1` and a milestone named `Launch v1.1.x`, the issues in `Launch v1.1.1` are more pressing.

If you are working on something that is not listed, first [make a new Issue](https://github.com/RefugeRestrooms/refuge-ios/issues/new) so your effort can be tracked.

#### Branch Naming Conventions

Make a new branch for each individual thing you are addressing. If you are working on an Issue with multiple bug fixes, there should be a new branch for each bug fix.

You should either name the branch after the issue number (e.g. `issue111`) or descriptively. If opting to name your branch descriptively, prefix it with the type of issue it is addressing, from the following list:

* `fix` - This branch is for addressing bugs
* `design` - This branch is for introducing *new* design work (if fixing previous design work, use `fix`)
* `feature` - This branch is for creating a brand new feature (if working on previous features, use `fix`)
* `pod` - This branch is for udpdating Pods or Frameworks
* `refactor` - This branch is for refactoring existing work

For example, if I wanted to work on addressing a bug - say I'm updating an expired API key - then I might name that branch `fix/update_expired_api_key`

Once done fixing that specific issue, make a pull request for that branch. If going on to work on another issue, do not work off of that branch, but rather branch off of the version of `refuge-ios` you originally forked.

#### Commit Message Conventions

Try and make your commit messages descriptive. Two- to three-word commit messages are usually not descriptive enough.

If your commit is addressing a specific Issue, you can reference that issue in your commit message with a pound sign then the number (e.g. #111). This will automatically a create link to that commit in the Issue, which is good for tracking purposes. You can see an example of this here: https://github.com/RefugeRestrooms/refuge-ios/issues/111

#### Code Style

Refuge uses the [New York Times Objective-C Style Guide](https://github.com/NYTimes/objective-c-style-guide)
