import json
import requests
from json.decoder import JSONDecodeError
from pagermaid import version
from pagermaid.listener import listener
from pagermaid.utils import obtain_message, alias_command,lang
from speedtest import distance, Speedtest,SpeedtestHTTPError
from os import remove, popen
import subprocess,re,os 


shell_cmds='''
#!/bin/bash
checkspeedtest() {
    if  [ ! -e '/pagermaid/workdir/speedtest-cli/speedtest' ]; then
        wget --no-check-certificate -qO speedtest.tgz https://install.speedtest.net/app/cli/ookla-speedtest-1.0.0-$(uname -m)-linux.tgz
        #wget --no-check-certificate -qO speedtest.tgz https://bintray.com/ookla/download/download_file?file_path=ookla-speedtest-1.0.0-$(uname -m)-linux.tgz 
    fi
    mkdir -p speedtest-cli && tar zxvf speedtest.tgz -C ./speedtest-cli/ > /dev/null 2>&1 && chmod a+rx ./speedtest-cli/speedtest
}

checkspeedtest
'''

speedtest_path="{}/speedtest-cli/speedtest".format(os.getcwd())
async def get(url):
    return requests.get(url)

async def speedtest_run(cmd):
    with open("{}/sprun.sh".format(os.getcwd()),"w") as f:
            f.write(cmd)
    res=subprocess.run("bash {}/sprun.sh".format(os.getcwd()), shell=True, check=True, stdout=subprocess.PIPE)
    return res 

def install_speedtest():
    if not os.path.exists(speedtest_path):
        with open("{}/spinstall.sh".format(os.getcwd()),"w") as f:
            f.write(shell_cmds)

        return subprocess.run("bash {}/spinstall.sh".format(os.getcwd()), shell=True, check=True, stdout=subprocess.PIPE)
    return 

@listener(is_plugin=True, outgoing=True, command=alias_command("ht"), 
          description=lang('speedtest_des'), 
          parameters="(Server ID)")
async def hou_speedtest(context):
    """ Tests internet speed using speedtest. """
    try:
        s=install_speedtest()
        test = Speedtest()
        best_srv=test.get_best_server()
        b_srv_id=best_srv["id"]
    except Exception as e:
        await context.reply(f"ht测速发生错误:{e}")
        return
    
    server = None
    if len(context.parameter) == 1:
            try:
                b_srv_id = int(context.parameter[0])
            except ValueError:
                await context.reply(lang('arg_error'))
                return
    msg = await context.edit(f"ht极速版测速中,目前选择的服务器id为:{b_srv_id}")
    cmd="{}  --accept-license -s {} -f json".format(speedtest_path,b_srv_id)
    try:
        sp_result =await speedtest_run(cmd)
        sp_result = sp_result.stdout.decode("utf-8")
        res_dict=json.loads(sp_result)

    except Exception as e:
        await context.edit(f"ht测速发生错误:{e}")
        return

    des = (
        f"**Speedtest ht极速版** \n"
        f"Server: `{res_dict['server']['name']} - "
        f"{res_dict['server']['location']}` \n"
        f"Host: `{res_dict['server']['host']}` \n"
        f"Upload: `{unit_convert(res_dict['upload']['bandwidth'] * 8)}` \n"
        f"Download: `{unit_convert(res_dict['download']['bandwidth'] * 8)}` \n"
        f"Latency: `{res_dict['ping']['latency']}` \n"
        f"Jitter: `{res_dict['ping']['jitter']}` \n"
        f"Timestamp: `{res_dict['timestamp']}`"
    )

    # 开始处理图片
    data = (await get(f"{res_dict['result']['url']}.png")).content
    with open('speedtest.png', mode='wb') as f:
        f.write(data)
    try:
        img = Image.open('speedtest.png')
        c = img.crop((17, 11, 727, 389))
        c.save('speedtest.png')
    except:
        pass
    try:
        await context.client.send_file(context.chat_id, 'speedtest.png', caption=des)
    except:
        return
    try:
        remove('speedtest.png')
    except:
        pass
    await msg.delete()

def unit_convert(byte):
    """ Converts byte into readable formats. """
    power = 1000
    zero = 0
    units = {
        0: '',
        1: 'Kb/s',
        2: 'Mb/s',
        3: 'Gb/s',
        4: 'Tb/s'}
    while byte > power:
        byte /= power
        zero += 1
    return f"{round(byte, 2)} {units[zero]}"
