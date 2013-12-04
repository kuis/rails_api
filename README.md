## Welcome to Brandscopic

![build status](https://www.codeship.io/projects/13757f10-3f31-0131-665a-6636da7c5096/status.jpg)

## Getting Started

1. At the command prompt, clone the project:

        git clone git@github.com:cjaskot/brandscopic.git

2. Change directory to <tt>brandscopic</tt> and start the web server:

        cd brandscopic

4. Create a database.yml file inside the config folder with the following content:

        development:
          adapter: postgresql
          database: brandscopic_dev
          encoding: unicode
          username: <your_user_name>
          password:
          server: 127.0.0.1

        test:
          adapter: postgresql
          database: brandscopic_test
          encoding: unicode
          username: <your_user_name>
          password:
          server: 127.0.0.1
          min_messages: WARNING

3. Make sure you have QT installed or run this (on Mac OSx):

        brew install
        brew install qt

  or the following if you are using ubuntu:

        sudo apt-get install libqt4-dev libxslt-dev libxml2-dev libpq-dev openjdk-7-jre

4. Install the required gems:

        bundle install

5. Create the local database

        rake db:create db:migrate


6. Run the local Solr server

        rake sunspot:solr:start

7. Insert the initial data

        rake db:seed

8. Run the tests to make sure everything works (optional)

        rake

9. Load some test data into the app

        rake db:populate:all

10. Reindex the data we just created

        rake sunspot:reindex

11. Stop the local Solr server because it will be executed on the next step

        rake sunspot:solr:stop

11. Start the local server

        foreman start

12. Go to http://localhost:5000/ and you should be able to login using:

        Email: admin@brandscopic.com
        Password: Adminpass12


## Rebuilding the Solr index

Sometimes the data can come out of sync during the development phase. Fortunately
there is a command we can use to build the entire index.
       rake sunspot:solr:index
