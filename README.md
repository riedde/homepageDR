# homepageDR

## build
For building a package opem terminal (Mac) and navigate into the repository.

## upload to localhost:8080
Type in ´ant deployLocal´. Then ant will build a package and automaticly upload it to eXist-db on localhost:8080. (The localhost:8080 has to be running and there has to be an eXist-db Instance on your local machine (vgl. code line 6 in build.xml).

## build for publishing
Type in ´ant deployPublic´. This will create a local .xar that you can manually upload to a database (recommended if the database is accessed via internet). 
