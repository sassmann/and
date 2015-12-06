#include <sys/socket.h>
#include <linux/netlink.h>
#include <linux/connector.h>
#include <linux/cn_proc.h>
#include <signal.h>
#include <errno.h>
#include <stdbool.h>
#include <unistd.h>
#include <string.h>
#include <stdlib.h>
#include <stdio.h>

#include "and.h"

bool need_exit = false;
/*
 * connect to netlink
 * returns netlink socket, or -1 on error
 */
int nl_connect()
{
	int rc;
	int nl_sock;
	struct sockaddr_nl sa_nl;

	nl_sock = socket(PF_NETLINK, SOCK_DGRAM, NETLINK_CONNECTOR);
	if (nl_sock == -1) {
		perror("socket");
		return -1;
	}

	sa_nl.nl_family = AF_NETLINK;
	sa_nl.nl_groups = CN_IDX_PROC;
	sa_nl.nl_pid = getpid();

	rc = bind(nl_sock, (struct sockaddr *)&sa_nl, sizeof(sa_nl));
	if (rc == -1) {
		perror("bind");
		close(nl_sock);
		return -1;
	}

	return nl_sock;
}

/*
 * subscribe on proc events (process notifications)
 */
int proc_set_ev_listen(int nl_sock, bool enable)
{
	int rc;
	struct __attribute__ ((aligned(NLMSG_ALIGNTO))) {
		struct nlmsghdr nl_hdr;
		struct __attribute__ ((__packed__)) {
			struct cn_msg cn_msg;
			enum proc_cn_mcast_op cn_mcast;
		};
	} nlcn_msg;

	memset(&nlcn_msg, 0, sizeof(nlcn_msg));
	nlcn_msg.nl_hdr.nlmsg_len = sizeof(nlcn_msg);
	nlcn_msg.nl_hdr.nlmsg_pid = getpid();
	nlcn_msg.nl_hdr.nlmsg_type = NLMSG_DONE;

	nlcn_msg.cn_msg.id.idx = CN_IDX_PROC;
	nlcn_msg.cn_msg.id.val = CN_VAL_PROC;
	nlcn_msg.cn_msg.len = sizeof(enum proc_cn_mcast_op);

	nlcn_msg.cn_mcast = enable ? PROC_CN_MCAST_LISTEN : PROC_CN_MCAST_IGNORE;

	rc = send(nl_sock, &nlcn_msg, sizeof(nlcn_msg), 0);
	if (rc == -1) {
		perror("netlink send");
		return -1;
	}

	return 0;
}

/*
 * handle a single process event
 */
int proc_handle_ev(int nl_sock)
{
	int rc;

	struct __attribute__ ((aligned(NLMSG_ALIGNTO))) {
		struct nlmsghdr nl_hdr;
		struct __attribute__ ((__packed__)) {
			struct cn_msg cn_msg;
			struct proc_event proc_ev;
		};
	} nlcn_msg;

	while (!need_exit) {
		rc = recv(nl_sock, &nlcn_msg, sizeof(nlcn_msg), 0);
		if (rc == 0) {
			/* shutdown? */
			return -1;
		} else if (rc == -1) {
			and_printf(0, "netlink receive error\n");
			return -1;
		}
		switch (nlcn_msg.proc_ev.what) {
			case PROC_EVENT_NONE:
				and_printf(1, "start listening to netlink...\n");
				break;
			case PROC_EVENT_FORK:
				//if (fork() == 0) /* handle event in child */
				//	return nlcn_msg.proc_ev.event_data.fork.parent_pid;
				//and_printf(1, "FORK pid=%d ppid=%d\n", nlcn_msg.proc_ev.event_data.fork.child_pid,nlcn_msg.proc_ev.event_data.fork.parent_pid);
				break;
			case PROC_EVENT_EXEC:
				if (fork() == 0) /* handle event in child */
					return nlcn_msg.proc_ev.event_data.exec.process_pid;
				and_printf(2, "EXEC pid=%d\n", nlcn_msg.proc_ev.event_data.exec.process_pid);
				break;
			case PROC_EVENT_UID:
			case PROC_EVENT_GID:
			case PROC_EVENT_SID:
			case PROC_EVENT_PTRACE:
			case PROC_EVENT_COMM:
			case PROC_EVENT_EXIT:
				break;
			default:
				and_printf(1, "unhandled proc_event %d\n", nlcn_msg.proc_ev.what);
				break;
		}
	}
	return 0;
}


