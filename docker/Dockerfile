# A common Perl + Mongo docker image
# Dockerizing MongoDB: Dockerfile for building MongoDB images
# Based on ubuntu:latest, installs MongoDB following the instructions from:
# http://docs.mongodb.org/manual/tutorial/install-mongodb-on-ubuntu/

FROM       ubuntu:14.04
MAINTAINER Rex Ren <rexr.nvidia.com>

RUN apt-get update
RUN apt-get install -y build-essential libexpat1-dev apache2 apache2-doc apache2-utils libapache2-mod-perl2 libapache2-mod-perl2-dev wget libmysqlclient-dev

ENV PERL_MM_USE_DEFAULT=1
RUN perl -MCPAN -e 'CPAN::Shell->install("YAML")'
RUN perl -MCPAN -e 'CPAN::Shell->install("Bundle::CPAN")'
RUN perl -MCPAN -e 'CPAN::Shell->install("XML::Parser")'
RUN perl -MCPAN -e 'CPAN::Shell->install("XML::Simple")'
RUN perl -MCPAN -e 'CPAN::Shell->install("Archive::Zip")'
RUN perl -MCPAN -e 'CPAN::Shell->install("SOAP::Lite")'
RUN perl -MCPAN -e 'CPAN::Shell->install("MongoDB")'
RUN perl -MCPAN -e 'CPAN::Shell->install("DBI")'
RUN perl -MCPAN -e 'CPAN::Shell->install("DBD::mysql")'
RUN perl -MCPAN -e 'CPAN::Shell->install("XML::Twig.pm")'
RUN perl -MCPAN -e 'CPAN::Shell->install("Class::ISA")'
RUN perl -MCPAN -e 'CPAN::Shell->install("Class::Accessor")'
RUN perl -MCPAN -e 'CPAN::Shell->install("Class::Data::Inheritable")'


ENV DOCKER=1
# ENTRYPOINT [""]
