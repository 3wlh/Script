<?php
    $password="*****";
    //$ip=$_REQUEST['ip'];
    //$pwd=$_REQUEST['pwd'];
    if($_SERVER['REQUEST_METHOD']=="POST"){
        $ip=$_POST['ip'];
        $pwd=$_POST['pwd'];
    }else if($_SERVER['REQUEST_METHOD']=="GET"){
        $ip=$_GET['ip'];
        $pwd=$_GET['pwd'];
    }
    $DOCUMENT_ROOT=$_SERVER['DOCUMENT_ROOT'];
    //设置时区
    date_default_timezone_set('Asia/Shanghai');
    //按指定格式输出日期
    $date=date('Y-m-d H:i');
 
?>
<!DOCTYPE html>
<html>
<head lang="zh_CN">
    <meta charset="UTF-8">
    <title>更新</title>
</head>
<body>
<h3>结果</h3>
<?php
    echo '<p>提交中时间：'.$date.'</p>';
    echo '<p>当前运行脚本所在目录：'.$DOCUMENT_ROOT.'</p>';
    //获取ip
    if($ip == null){
        echo '<p>您未更新IP！</p>';
        exit;
    }else{
        echo '<p>您IP为：'.$ip.'</p>';
    }
    //判断密码
    if($pwd != $password ){
        echo '<p>更新密码错误！</p>';
        echo '<p>您密码为：'.$pwd.'</p>';
        exit;
    }
    //设置文件输出内容和格式
    // 显示ip
    //$out_put_string="<!DOCTYPE html>\n<html>\n<head>\n<meta charset=\"UTF-8\">\n<title>IP</title>\n</head>\n<body>\n<div style=\"display: grid; place-items: center; height: 80vh;\">\n\t<table border=\"5\" bordercolor=\"#FF6688\" cellpadding=12 cellspacing=5 width=350>\n\t\t<tr>\n\t\t\t<th colspan=\"2\"><h2>IP:\t$ip</h2></th>\n\t\t</tr>\n\t\t<tr>\n\t\t\t<th colspan=\"2\"><a href=\"http://$ip:8\">OpenWrt</a></th>\n\t\t</tr>\n\t</table>\n</div>\n</body>\n</html>";
    // 自动跳转
    $out_put_string="<!DOCTYPE html>\n<html lang=\"zh-CN\">\n<script language=\"javascript\" type=\"text/javascript\">\n// 以下方式直接跳转\nwindow.location.href='http://$ip:8';\n// 以下方式定时跳转\n//setTimeout(\"javascript:location.href='http://$ip:8'\", 5000);\n</script>";
    //打开文件,（写入文件）
    @$fp=fopen("index.html",'w');
    flock($fp,LOCK_EX);
    if(!$fp){
        echo "<p><strong>您的IP更新未完成！</strong></p></body></html>";
        exit;
    }
    //将数据写入到文件
    fwrite($fp,$out_put_string,strlen($out_put_string));
    flock($fp,LOCK_UN);
    //关闭文件流
    fclose($fp);
    echo "<p>数据保存完成</p>";
?>
</body>
</html>