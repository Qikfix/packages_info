# packages_info

**Disclaimer**: This project or the binary files available in the `Releases` area are `NOT` delivered and/or released by Red Hat. This is an independent project to help customers and Red Hat Support team. The main idea of this code is to be used as a reference for RFE `Request for Enhancement`.

# Purpose
- You can call the script, and the same will collect the errata info, also, the packages of each content view. Then, you can generate a complete report from all the packages on all the CVs, with the errata information, or you can just select one specific file that you would like to query. The search will be against all the available CVs as well.

# Usage
Main menu
```
./packages_info.sh
Please, call ./packages_info.sh with the parameter
 --full # To generate a complete list of all the packages in the content view
 --package <package name> # To generate a list of packages in the content view, based on the name

exiting ...
```

Passing a single file to search
```
./packages_info.sh --package katello-agent
Searching by package katello-agent
Please, check /tmp/full_report.csv
```

Collecting the whole information
```
./packages_info.sh --full
Collecting all the packages information
Please, check /tmp/full_report.csv
```

In the end, you can open the `CSV` file located at `/tmp/full_report.csv` in your Spreadsheet application, and apply some filters in a way that you can have the information you are looking for.