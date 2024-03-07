#!/bin/sh
rsync -avz --delete --exclude='.git/' -e 'ssh -p 22' public/  ubuntu@www.tister.cn:/data/tister.cn

