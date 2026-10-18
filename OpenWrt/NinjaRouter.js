// 定义：直连 + 指定局域网设备不走代理
function main(config) {
  // 不走代理的设备（来源IP）
  const bypassDevices = [
    // 这台设备的所有流量直连
    "10.10.10.100/32",
  ];
  
  // 不走代理的直连域名
  const myDirectDomains = [
    // "example.com",
    "19970101.xyz",
    "snssdk.com",
    "muguacloud.ninja",
    "appstorrent.ru",
    "trae.cn",
  ];
  
  // 不走代理的设备直连端口
  const myDirectPorts = [
    "65010",
  ];

 // ################ 生成规则 ################
  // IP规则
  const sourceRules = bypassDevices.map(ip => `SRC-IP-CIDR,${ip},DIRECT`);

  // 端口规则
  const protRules = myDirectPorts.map(p => `DST-PORT,${p},DIRECT`);

  // 直连规则
  const directRules = [
    ...myDirectDomains.map(d => `DOMAIN-SUFFIX,${d},DIRECT`),
    // Cloudflare
    "DOMAIN-SUFFIX,cloudflare.com,DIRECT",
    // 腾讯服务
    "DOMAIN-SUFFIX,tencentgames.com,DIRECT",
    "DOMAIN-SUFFIX,tencentyun.com,DIRECT",
    "DOMAIN-SUFFIX,myqcloud.com,DIRECT",
    "DOMAIN-SUFFIX,qcloud.com,DIRECT",
    "DOMAIN-SUFFIX,tencent-cloud.net,DIRECT",
    "DOMAIN-SUFFIX,gtimg.com,DIRECT",
    "DOMAIN-SUFFIX,idqqimg.com,DIRECT",
    "DOMAIN-SUFFIX,qpic.cn,DIRECT",
    "DOMAIN-SUFFIX,wegame.com,DIRECT",
    "DOMAIN-SUFFIX,sngsdk.com,DIRECT",
    "DOMAIN-SUFFIX,tcdnos.com,DIRECT",
    // 所有中国 IP 直连
    "GEOIP,CN,DIRECT,no-resolve",
  ];

  if (!Array.isArray(config.rules)) config.rules = [];

  // 来源IP规则放在最前面（优先级最高），再接域名直连规则，最后是订阅原规则
  config.rules = sourceRules.concat(directRules, protRules, config.rules);

 // ################ DNS返回真实IP ################
  if (config.dns && Array.isArray(config.dns["fake-ip-filter"])) {
    const realIp = [
      "+.qq.com", "+.tencentgames.com", "+.myqcloud.com",
      "+.gtimg.com", "+.tencentyun.com", "+.qcloud.com",
      "+.pool.ntp.org", "+.ntp.org.cn", "ntp.*.com",
      ...myDirectDomains.map(d => `+.${d}`),
    ];
    config.dns["fake-ip-filter"] = config.dns["fake-ip-filter"].concat(realIp);
  }

  return config;
}
