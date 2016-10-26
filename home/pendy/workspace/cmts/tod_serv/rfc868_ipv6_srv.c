/* Simple RFC868 server for Linux/gcc
   (c) 2010 Jonathan Andrews (jon at jonshouse dot co dot uk)
   This code is Covered under the GPL V2 license, see licence.txt for details

   This code was written so I could sync machines with "rdate"

   Version 1.0
   Last Changed 17 feb 2010
*/

 
#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <time.h>

#ifndef MAXDATALEN
#define MAXDATALEN  (4096)
#endif

static unsigned char msg[MAXDATALEN];

int main(void)
{
    int rc;
    char thetime[4];
    time_t  t;
    struct tm *tm;

    struct sockaddr_in6 stSockAddr;
    struct sockaddr_in6 in_addr;
    struct in6_addr from;
    int addr_len;
    
    int SocketFD = socket(AF_INET6, SOCK_DGRAM, 0);

    struct timeval  timeout;	
    fd_set          fds_send;
    fd_set          fds_read;
    char 	ipstr[INET6_ADDRSTRLEN];

	if(-1 == SocketFD)
	{
  		perror("can not create UDP socket");
  		exit(EXIT_FAILURE);
	}

	memset(&stSockAddr, 0, sizeof(struct sockaddr_in));
	stSockAddr.sin6_family = AF_INET6;
	stSockAddr.sin6_port = htons(37);
	stSockAddr.sin6_addr = in6addr_any;
	stSockAddr.sin6_scope_id = 0;

	if (-1 == bind(SocketFD,(const struct sockaddr *)&stSockAddr, sizeof(struct sockaddr_in6)))
	{
  		perror("error bind failed");
  		close(SocketFD);
  		exit(EXIT_FAILURE);
	}

	for (;;)							// Accept socket connections, reply then hangup
	{
        FD_ZERO(&fds_read);        
        FD_ZERO(&fds_send);        
        FD_SET(SocketFD, &fds_read);
        FD_SET(SocketFD, &fds_send);
        
        timeout.tv_sec = 5;
        timeout.tv_usec = 0;
        
        rc = select(SocketFD + 1 , &fds_read, NULL, NULL, &timeout);

        if (rc <= 0)
        {
            //printf("Timeout ....\n");
            continue;
        }
        else
        {            
            if ( FD_ISSET(SocketFD, &fds_read) )
            {                
		addr_len = sizeof(in_addr);
                rc = recvfrom(SocketFD, (void *)msg, MAXDATALEN, 0, (struct sockaddr *)&in_addr, (socklen_t *)&addr_len);
		memcpy(&from, &(in_addr.sin6_addr), sizeof(from));
		
		time(&t);
		tm = localtime(&t);
		char *ip = inet_ntop(AF_INET6, &(in_addr.sin6_addr), ipstr ,sizeof(ipstr));
		if (ip)
                    printf("Got connection : Ip[%s] Time[%d-%d-%d %d:%d:%d] \n", ip,
						(1900+tm->tm_year), (1+tm->tm_mon), tm->tm_mday,
						tm->tm_hour, tm->tm_min, tm->tm_sec);
                if ( 1 /*FD_ISSET(SocketFD, &fds_send) */ )
                {
		    //tzset();
                    //time(&t);               // get time from linux kernel since midnight 1970
                    t = t - 2085978496;	    // subtract 70 years, rfc868 is since midnight 1900
		    t += 8*60*60;           // TZ-Beijing GMT+8
                    long unsigned int bigtime = htonl(t);	  // convert value to network portable long integer
                    memcpy(thetime,&bigtime,4);				// copy it - avoid compiler warnings
                    
                    rc = sendto(SocketFD, (void *)thetime, 4, 0, (struct sockaddr *)&in_addr, addr_len);

                    if (rc != 4)
                    {
                        printf("Sent failed[%d].........\n", rc);
                    }
                }
            }
        }        
	printf("Got connection\n");
	}
}


