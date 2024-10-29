<?php
    $IP=$_GET['IP'];
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
    if($IP == null){
        echo '<p>您未更新IP！</p>';
        exit;
    }else{
        echo '<p>您IP为：'.$IP.'</p>';
    }
    //设置文件输出内容和格式
    $out_put_string="<!DOCTYPE html>\n<html>\n<head>\n\t<h4>IP:\t$IP<h4>\n\t<a href=\"http://".$IP.":8\">OpenWrt</a>\n</head>\n</html>";
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