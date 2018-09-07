FROM tensorflow/tensorflow:latest-gpu

MAINTAINER Thomas Wood <thomas@synpon.com>

COPY ./scene-graph-TF-release /app/scene-graph-TF-release

COPY ./sg_checkpoint.zip /app/scene-graph-TF-release/sg_checkpoint.zip

RUN mkdir /app/scene-graph-TF-release/data

COPY ./vg_data.zip /app/scene-graph-TF-release/data/vg_data.zip

RUN cd /app/scene-graph-TF-release && \
    unzip sg_checkpoint.zip && \
    rm sg_checkpoint.zip && \
    cp checkpoints/dual_graph_vrd_final_iter2.ckpt.index checkpoints/dual_graph_vrd_final_iter2.ckpt && \
    cd data && \
    unzip vg_data.zip && \
    rm vg_data.zip && \
    cd /

COPY ./pytorch /app/pytorch

RUN pip install Cython easydict graphviz pyyaml

RUN cd /app/scene-graph-TF-release/lib && \
    make && \
    cp roi_pooling_layer/src/* /usr/local/lib/python2.7/dist-packages/tensorflow/user_ops && \
    cd /usr/local/lib/python2.7/dist-packages/tensorflow/user_ops && \
    TF_INC=/usr/local/lib/python2.7/dist-packages/tensorflow/include && \
    TF_LIB=/usr/local/lib/python2.7/dist-packages/tensorflow && \
    nvcc -std=c++11 -c -o roi_pooling_op_gpu.cu.o roi_pooling_op_gpu.cu.cc \
      -I $TF_INC -I /usr/local -L$TF_LIB -ltensorflow_framework \
      -D GOOGLE_CUDA=1 -x cu -Xcompiler -fPIC --expt-relaxed-constexpr -D_GLIBCXX_USE_CXX11_ABI=0  && \
    g++ -std=c++11 -shared -o roi_pooling_op_gpu.so roi_pooling_op.cc roi_pooling_op_gpu.cu.o \
      -I $TF_INC -fPIC -L /usr/local/cuda-9.2/lib64/ -L /usr/local/cuda-9.0/targets/x86_64-linux/lib \
      -lcudart -L$TF_LIB -ltensorflow_framework -D_GLIBCXX_USE_CXX11_ABI=0 && \
    cp roi_pooling_op_gpu.so /app/scene-graph-TF-release/lib/roi_pooling_layer/roi_pooling_op_gpu.so

# RUN /usr/bin/python -c "import tensorflow as tf"

# RUN cd /app/scene-graph-TF-release && \
#    wget https://www.dropbox.com/s/2rgq9vcx1jpeyjp/sg_checkpoint.zip && \
#    unzip sg_checkpoint.zip && \
#    rm sg_checkpoint.zip

RUN apt-get update && \
    apt-get install -y python-tk

WORKDIR "/app"
CMD ["/bin/bash"]
