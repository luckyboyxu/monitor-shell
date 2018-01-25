<?php
require_once('/home/www/html/dist.500wan.com/html/inc/dist.php');
$node = array_merge($_DISTCONFIG_['node'],$_DISTCONFIG_['node_cn']);
$redis_ip = '10.20.25.129';
$redis_port = 6379;
$redis = new Redis();
$rep = $redis->connect($redis_ip, (int)$redis_port);
$key = 'fs|'.$argv[1].'|dist';
$nodes = array();
for($i=0;$i<count($node);$i++){
    array_push($nodes,array("host"=>$node[$i]));
}
$redis->setex($key,10*60,json_encode($nodes));
$redis->close();
?>