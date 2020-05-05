#Grab the latest alpine image
FROM sanchom/pollen:latest

RUN apt-get -y update && apt-get -y install \
    git

# Installing my Racket application

RUN raco pkg install --deps search-auto --scope installation pollen-citations-mcgill
RUN raco pkg install --deps search-auto --scope installation hyphenate uuid

RUN cd /opt && git clone https://github.com/sanchom/associate.git
RUN chmod -R a+rw /opt/associate
RUN chmod -R a+rw /usr/share/racket/pkgs

# Add this webapp's code
ADD ./server /opt/server/
RUN raco pkg install -i --no-setup --deps search-auto -n my-heroku-app --copy /opt/server
RUN raco setup -DK --fail-fast

# Add some static files
ADD ./static-files /opt/static-files

# Expose is NOT supported by Heroku
# EXPOSE 8080

# Run the image as a non-root user
RUN useradd -m myuser
USER myuser


CMD racket -l my-heroku-app/server