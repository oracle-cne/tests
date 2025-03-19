FROM container-registry.oracle.com/os/oraclelinux:8
RUN dnf install -y nginx && dnf clean all

COPY repo /opt/charts
COPY values /opt/values
COPY nginx.conf /etc/nginx/nginx.conf

EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
