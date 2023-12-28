FROM ubuntu:20.04 AS builder
WORKDIR /opt/build
RUN apt-get update
RUN apt-get install -y \
    build-essential \
    curl
RUN curl https://sh.rustup.rs -sSf | bash -s -- -y
ENV PATH="/root/.cargo/bin:${PATH}"
# Copy Cargo files
COPY ./Cargo.toml .
COPY ./Cargo.lock .
COPY ./libs libs
COPY build.rs .

# Create fake main.rs file in src and build
RUN mkdir ./src && echo 'fn main() { println!("Dummy!"); }' > ./src/main.rs
RUN echo 'fn main() { println!("Dummy!"); }' > ./src/utils.rs
RUN echo 'fn main() { println!("Dummy!"); }' > ./src/hbbr.rs
RUN cargo build --release
# Copy source files over
RUN rm -rf ./src
COPY . .

# The last modified attribute of main.rs needs to be updated manually,
# otherwise cargo won't rebuild it.
RUN touch -a -m ./src/main.rs
RUN touch -a -m ./src/utils.rs
RUN touch -a -m ./src/hbbr.rs
RUN cargo build --release


FROM ubuntu:20.04
WORKDIR /opt/run
RUN apt-get update
RUN apt-get install -y \
    build-essential \
    curl
COPY --from=builder /opt/build/target/release/hbbr .
COPY --from=builder /opt/build/target/release/hbbs .
COPY --from=builder /opt/build/target/release/rustdesk-utils .
