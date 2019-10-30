import shlex
from subprocess import Popen, PIPE,call,check_output
import argparse,datetime,subprocess


if __name__ == "__main__":

    parser = argparse.ArgumentParser(description="Build Docker file for prs comparison")

    parser.add_argument("--image", type= str,
                        help="name of image",default = 'check_prs')
    parser.add_argument("--version", type= str,
                        help="version value, e.g.0.001",required = True)
    parser.add_argument("--push",action = 'store_true')
    parser.add_argument("--args",type = str,default = '')
    args = parser.parse_args()

    
    basic_cmd = 'docker build -t eu.gcr.io/finngen-refinery-dev/' + args.image +':' +args.version
    cmd = basic_cmd + ' -f Dockerfile ..' + ' ' + args.args
    print(cmd)
    call(shlex.split(cmd))

    if args.push:
        current_date = datetime.datetime.today().strftime('%Y-%m-%d')
        git_hash = subprocess.check_output(['git','rev-parse','HEAD']).decode().strip()
        cmd = 'gcloud docker -- push eu.gcr.io/finngen-refinery-dev/' + args.image +':' + args.version
        with open('./docker.log','a') as o:o.write(' '.join([current_date,git_hash,cmd]) + '\n')
        call(shlex.split(cmd))
        
