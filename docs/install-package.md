# Installing Packages

We will now be going to update your computer's repositories and install new packages, offline!


## Transferring Project

On `cube/projects` folder, delete the old project and replace it with the new project.

![](_media/img50.png)

Navigate back to `cube`, then double click `cube` to launch.

![](_media/img03.png)

## Updating Computer's Repository

Since we have downloaded new repositories, we need to update our computer's outdated repositories first before installing new packages.

Click `Cube => System => Update Computer's Repositories`.

![](_media/img51.png)

A dialog from your Linux system will appear asking for your credentials.

![](_media/img52.png)

!> Package installation may fail if you don't update your computer's repositories first. This is beacuse your computer's record on the package is outdated and will not match with the new package.

## Installing Package Updates

To install all updates, click `Cube => Install => Mark All Downloaded for Installation` 

And then click `Cube => Install => Install All Marked Packages` to install them.

!> Note that Cube might prevent installation of some apps with packages that needs to be downloaded. To install packages with satisfied downloaded packages, click `Cube => Install => Install All Satisfied Downloaded Packages`

![](_media/img90.png)

## Installing Package

Search for the package you want to be installed. To display all downloaded packages, click `Asterisk => Downloaded` to change the package filter.

![](_media/img55.png)

Or search via search bar. Then click `Install`.

![](_media/img56.png)

The package viewer will appear, showing the application's description and the list of packages that will be installed.

Click `Install` to begin installation.

![](_media/img57.png)

A dialog will appear asking for your credentials.

![](_media/img58.png)

And then a terminal will be launched, showing the current installation progress. This will automatically close when done.

![](_media/img60.png)

You can check the complete installation output in `cube/cube-system/data/temp/install-log.txt`

And yey! Your application is now installed!

![](_media/img61.png)

![](_media/img62.png)

![](_media/img63.png)

## Cleaning Project

Now that the packages are installed, we can now remove these packages from the project to save space.

Click `Cube => Project => Clean Project`.

![](_media/img64.png)

A summary of packages to be removed will be displayed.

![](_media/img65.png)

Successfully cleaned!

![](_media/img66.png)

!> Broken packages (Packages which have been partially downloaded will be also removed)