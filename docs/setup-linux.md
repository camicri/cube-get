# Setting up on Offline Linux

In this guide, I'm going to show you how to setup Cube on an offline Linux computer. Here, I'll be using Ubuntu 16.04 LTS. Note that this computer doesn't have internet connection.

![](_media/img01.png)

## Setting up Cube

Copy and extract the downloaded cube zip in your home directory.

![](_media/img02.png)

Then, open `cube` folder.

![](_media/img03.png)

## Launching Cube

To Launch Camicri Cube, just double click the `cube` application.
A terminal and a web browser will appear.

![](_media/img04.png)



## Creating Project
Projects are essential in the Cube application. A project contains the information about your computer. This includes the list of repositories, currently installed packages and the architecture of your computer.

Projects created in cube will be saved in `cube/projects` directory.

Provide a name for your project (`myproject` in this case) and click `Create` to create the project.

![](_media/img05.png)

![](_media/img07.png)

Click `Open` to load the project.

Cube now loads your project. On this stage, Cube is now reading your project's repositories to check for all available, installed and needs to be updated packages.

![](_media/img08.png)

Once done, the Cube's main interface will be displayed.

![](_media/img10.png)

## Transferring Project

Since this Linux computer is offline, you will not be able to download packages.
We need to find a computer with internet connection.

The project we have created earlier will be transferred on a computer with internet connection.

Close the Cube by clicking the `Cube` icon and `Quit`

![](_media/img12.png)

On the project's folder `cube/projects`, compress the newly created project and save it to any removable device.

![](_media/img14.png)

On the [next](/setup-windows) guide, we will be going to download packages on another computer with internet connection.