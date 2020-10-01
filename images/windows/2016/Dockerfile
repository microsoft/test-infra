# Use server core instead of nano because installing powershell is hard..
FROM mcr.microsoft.com/windows/servercore:ltsc2016

WORKDIR /
COPY "." .

RUN cd images/windows/ && dir && install.cmd