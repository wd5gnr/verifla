The basic idea is this:

In a project directory you have your normal design and a symbolic link to the
main verifla directory. You must put the include file in your project directory
and include the verifla symlink as a library. However, your tool must look in
your working directory first for include files.

You can also (as demo3 does) simply set your tool (in the go script, in this case) to
search the library whereever it is as long as it picks up your local include.


