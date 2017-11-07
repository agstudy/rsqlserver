FROM ruaridhw/rclr:latest
LABEL org.label-schema.license="GPL-2.0" \
      org.label-schema.vcs-url="https://github.com/agstudy/rsqlserver" \
      org.label-schema.vendor="" \
      maintainer="Ruaridh Williamson <ruaridh.williamson@gmail.com>"

ENV workingdir /usr/local/R

COPY . "$workingdir"
WORKDIR "$workingdir"

RUN Rscript -e "devtools::install_github('serhatcevikel/rClr@03f65ef')"

CMD ["R"]
