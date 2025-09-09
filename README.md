## 项目说明

```shell
CNN_FPGA
├── CNN_FPGA.sim
│   ├── sim_1
│   └── sources_1
│       ├── TB # 测试文件testbench
│       │   ├── ANNfull_TB.v
│       │   ├── FindMax_TB.v
│       │   ├── IEEE162IEEE32_TB.v
│       │   ├── IntegrationConvPart_TB.v
│       │   ├── Lenet_TB.v
│       │   ├── MaxPoolMuti_TB.v
│       │   ├── MaxPoolSingle_TB.v
│       │   ├── RFselector_TB.v
│       │   ├── UsingTheRelu16_TB.v
│       │   ├── UsingTheRelu_TB.v
│       │   ├── activationFunction_TB.v
│       │   ├── convLayerMulti_TB.v
│       │   ├── convLayerSingle_TB.v
│       │   ├── convUnit_TB.v
│       │   ├── floatAdd16_TB.v
│       │   ├── floatAdd_TB.v
│       │   ├── floatMult16_TB.v
│       │   ├── floatMult_TB.v
│       │   ├── layer_TB.v
│       │   ├── max_TB.v
│       │   ├── padding_TB.v
│       │   ├── processingElement16_TB.v
│       │   ├── processingElement_TB.v
│       │   ├── softmax_TB.v
│       │   └── weightMemory_TB.v
│       ├── imports # 引用的开源参考代码,修正了其中一些错误
│       │   ├── IEEE162IEEE32.v
│       │   ├── RFselector.v
│       │   ├── UsingTheRelu.v
│       │   ├── UsingTheRelu16.v
│       │   ├── activationFunction.v
│       │   ├── convLayerSingle.v
│       │   ├── convUnit.v
│       │   ├── floatAdd.v
│       │   ├── floatAdd16.v
│       │   ├── floatMult.v
│       │   ├── floatMult16.v
│       │   ├── processingElement.v
│       │   ├── processingElement16.v
│       └── new # 新加入的部分
│           ├── ANNfull.v
│           ├── FindMax.v
│           ├── IntegrationConvPart.v
│           ├── Lenet.v
│           ├── MaxPoolMulti.v
│           ├── MaxPoolSingle.v
│           ├── convLayerMulti.v
│           ├── layer.v
│           ├── max.v
│           ├── padding.v
│           └── weightMemory.v
├── CNN_FPGA.xpr # vivado工程文件
├── note.txt
├── temp_simulation.tcl
├── vivado.jou
└── vivado.log
Code
├── CNN
│   ├── Dataset # 项目所用是聚集SPOT-10
│   │   ├── test-images-idx3-ubyte.gz
│   │   ├── test-labels-idx1-ubyte.gz
│   │   ├── train-images-idx3-ubyte.gz
│   │   └── train-labels-idx1-ubyte.gz
│   ├── README.md
│   ├── best_student.pth # 蒸馏过的学生模型
│   ├── best_student_normal.pth # 未蒸馏模型
│   ├── best_teacher.pth # 教师模型
│   ├── data_loader.py
│   ├── extractData.py
│   ├── loss.py
│   ├── model.py # 模型实现
│   ├── quantification.py # 权重量化
│   └── train.py # 训练代码
├── simulate.py # 使用python实现的仿真器
├── simulateResValid.py # 结果验证
└── testSetQuantify.py # 测试集量化

Data
├── Cut # 一些仿真结果
│   ├── 16位乘法器.png
│   ├── 16位加法器.png
│   ├── ConvSingle.png
│   ├── Pad出现未知x,原因是索引错误.png
│   ├── Pad索引成功.png
│   ├── relu激活函数.png
│   ├── 使用归一化数据后整体MSE下降.png
│   ├── 单核卷积仿真.png
│   ├── 卷积层仿真.png
│   ├── 取最大值.png
│   ├── 多通道卷积仿真.png
│   └── 模型仿真结果,acc93.33%.png
├── Weight
│   ├── distilled # 蒸馏后权重
│   │   ├── conv1_hex.txt
│   │   ├── conv2_hex.txt
│   │   ├── conv3_hex.txt
│   │   ├── fc1_hex.txt
│   │   ├── fc2_hex.txt
│   │   ├── fc3_hex.txt
│   │   └── fc4_hex.txt
│   └── undistilled
├── small_test_image.txt # 小样本测试集,用于简单调试
├── test_images.xlsx # 测试集和标签
├── test_images_hex.txt # 测试数据集
├── test_labels.txt # 测试集标签
├── test_output.txt # 测试集输出
└── 数据集.zip
```

项目主体源代码应有如上结构。使用本项目,需要作以下修改:

```
在ANNfull.v文件中,修改全连接层权重路径,例如:
将D:/Material/CSDP/Data/Weight/distilled/fc1_hex.txt替换为YOUR_WEIGHT_PATH/fc1_hex.txt
其它权重路径类似
```

```
在Lenet_TB.v中,修改卷积层权重路径,例如:
将D:/Material/CSDP/Data/Weight/distilled/conv1_hex.txt替换为YOUR_WEIGHT_PATH/conv1_hex.txt
```

```
在FindMax.v中,修改测试结果路径:
将D:/Material/CSDP/Data/test_output.txt替换为REAL_TEST_OUT_PATH
```

然后在Vivado中运行仿真即可,如果测试结果无法被写入文件,可以查看左下角TCL命令栏的输出结果。



