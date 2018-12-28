#!/bin/bash
cd ../../bcos/tool
node accountManager.js > godInfo.txt
cat godInfo.txt |grep address
