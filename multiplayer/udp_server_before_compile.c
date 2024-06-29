// Compiled with
// gcc udp_server.c -o udp_server.dll -shared -static -L./ -luv -lWs2_32 -ldbghelp -luserenv -lpthread -lOle32 -lIphlpapi

#include <uv.h>
#include <stdlib.h>
#include <string.h>
#include <stdio.h>
#include <pthread.h>
#include <semaphore.h>
#include <windows.h> // For Sleep function

// Packet structure for storing incoming packets
typedef struct packet {
    char* data;
    ssize_t length;
    struct packet* next;
} packet_t;

// Server structure to handle UDP server state and packets
typedef struct {
    uv_udp_t handle;
    uv_loop_t *loop;
    packet_t* packets;
    packet_t* last_packet;
    pthread_mutex_t lock;
    pthread_t thread;
    sem_t sem;
    int running;
    int sleep_interval;
} udp_server_t;

// Allocate buffer for incoming data
static void alloc_buffer(uv_handle_t *handle, size_t suggested_size, uv_buf_t *buf) {
    buf->base = (char *)malloc(suggested_size);
    buf->len = suggested_size;
}

// Handle incoming data
static void on_read(uv_udp_t *req, ssize_t nread, const uv_buf_t *buf, const struct sockaddr *addr, unsigned flags) {
    if (nread > 0) {
        udp_server_t* server = (udp_server_t*)req->data;
        packet_t* packet = (packet_t*)malloc(sizeof(packet_t));
        packet->data = (char*)malloc(nread);
        memcpy(packet->data, buf->base, nread);
        packet->length = nread;
        packet->next = NULL;

        pthread_mutex_lock(&server->lock);
        if (server->last_packet) {
            server->last_packet->next = packet;
        } else {
            server->packets = packet;
        }
        server->last_packet = packet;
        pthread_mutex_unlock(&server->lock);

        sem_post(&server->sem);  // Signal that a packet is available
    }
    free(buf->base);
}

// Thread function to run the UDP server
void* udp_server_thread(void* arg) {
    udp_server_t* server = (udp_server_t*)arg;
    while (server->running) {
        uv_run(server->loop, UV_RUN_NOWAIT);
        Sleep(server->sleep_interval);  // Sleep for the interval set at server creation in lua
    }
    return NULL;
}

// Start the UDP server
__declspec(dllexport) udp_server_t* start_udp_server(const char* ip, int port, int sleep_interval) {
    udp_server_t* server = (udp_server_t*)malloc(sizeof(udp_server_t));
    server->loop = uv_default_loop();
    server->packets = NULL;
    server->last_packet = NULL;
    pthread_mutex_init(&server->lock, NULL);
    sem_init(&server->sem, 0, 0);
    server->running = 1;
    server->sleep_interval = sleep_interval;

    uv_udp_init(server->loop, &server->handle);
    server->handle.data = server;

    struct sockaddr_in recv_addr;
    uv_ip4_addr(ip, port, &recv_addr);
    uv_udp_bind(&server->handle, (const struct sockaddr*)&recv_addr, 0);
    uv_udp_recv_start(&server->handle, alloc_buffer, on_read);

    pthread_create(&server->thread, NULL, udp_server_thread, server);

    return server;
}

// Retrieve pending packets
__declspec(dllexport) char* get_pending_packets(udp_server_t* server, ssize_t* length) {
    if (sem_trywait(&server->sem) != 0) {
        *length = 0;
        return NULL;
    }

    pthread_mutex_lock(&server->lock);
    if (server->packets == NULL) {
        pthread_mutex_unlock(&server->lock);
        *length = 0;
        return NULL;
    }

    packet_t* packet = server->packets;
    server->packets = packet->next;
    if (server->packets == NULL) {
        server->last_packet = NULL;
    }
    pthread_mutex_unlock(&server->lock);

    char* data = packet->data;
    *length = packet->length;
    free(packet);

    return data;
}

// Free packet data, not done in lua with C.sleep because of mysterious crashes
__declspec(dllexport) void free_packet_data(char* data) {
    if (data) {
        free(data);
    }
}

// Stop the server
__declspec(dllexport) void stop_server(udp_server_t* server) {
    server->running = 0;
    pthread_join(server->thread, NULL);
    uv_stop(server->loop);
    pthread_mutex_destroy(&server->lock);
    sem_destroy(&server->sem);
    free(server);
}
