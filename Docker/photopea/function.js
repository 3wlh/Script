(function() {
  // 提前定义空FNTS兜底，避免pp.js立即执行报错
	if (!window.FNTS) {window.FNTS = { subsetNames: [], cats: [], list: [] };}
  // 创建FNTS脚本标签，强制同步执行
  const fntsScript = document.createElement("script");
  const fntsSrc = "rsrc/fonts/fnts-module.js";
  const fntsScriptSrc = `${fntsSrc}?t=${new Date().getTime()}`;
  fntsScript.src = fntsScriptSrc;
  //fntsScript.async = false;
  // 插入head头部，优先于pp.js执行
  document.head.insertBefore(fntsScript, document.head.firstChild);
})();