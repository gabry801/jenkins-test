FROM ubuntu:14.04
RUN sudo apt-get update && sudo apt-get install -y wget
RUN sudo useradd gabriele
