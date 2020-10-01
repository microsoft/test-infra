# Use server core instead of nano because installing powershell is hard..
FROM mcr.microsoft.com/windows/servercore:ltsc2019

WORKDIR /
COPY "." .

#TODO Find long term solution to maintaining windows 2019 docker files wrt PSW/DCAP

#CAB File for the Windows Server 2019 Installation of the PSW on Windows Update
ENV PSW_CAB 029b5021-3a54-4c7c-b215-3b3516b69563_d272d1c926cd2bde1515c0f684a457b6e61c5cb6.cab
 
#CAB File for the Windows Server 2019 Installation of DCAP on Windows Update
ENV DCAP_CAB d3edbd89-771e-4dbd-937f-c8110af67029_60a76d0377a087444d5c8918f63ef5d493ff8013.cab
 
# Download the latest PSW And DCAP CAB files and then expand the required files into the appropriate directories
# Do this in one command to minimize container layers (reduces the size of the container)
 
RUN curl.exe -O http://download.windowsupdate.com/c/msdownload/update/driver/drvs/2020/08/%PSW_CAB% \
&& expand.exe /R %PSW_CAB% /F:sgx_urts.dll c:\windows\system32 \
&& expand /R %PSW_CAB% /F:*.dll c:\Windows\System32 \
&& expand /R %PSW_CAB% /F:third_party.rtf c:/ \
&& del /q %PSW_CAB% \
&& curl.exe -O http://download.windowsupdate.com/c/msdownload/update/driver/drvs/2020/08/%DCAP_CAB% \
&& expand /R %DCAP_CAB% /F:*.dll c:\Windows\System32 \
&& expand /R %DCAP_CAB% /F:License.txt c:/ \
&& expand /R %DCAP_CAB% /F:ThirdPartyLicenses.txt c:/ \
&& del /q %DCAP_CAB%

RUN cd images/windows/ && dir && install.cmd