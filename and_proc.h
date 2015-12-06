#ifndef AND_PROC_H
#define AND_PROC_H

int nl_connect(void);
int proc_set_ev_listen(int nl_sock, bool enable);
int proc_handle_ev(int nl_sock);

#endif /* AND_PROC_H */
