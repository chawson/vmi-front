window.addEventListener('load', () => {

    var iframe = document.getElementById("iframe");
    var iframeDoc = iframe.contentWindow.document

    //start1-处理iframe页面相关事件不触发
    var DOMContentLoaded = iframeDoc.createEvent('UIEvents')
    DOMContentLoaded.initUIEvent('DOMContentLoaded',false,false)

    var WindowLoaded = iframeDoc.createEvent('UIEvents')
    WindowLoaded.initUIEvent('load',false,false)

    var dispatchEvts = ()=>{
        var timer = setTimeout(()=>{
            iframe.contentWindow.dispatchEvent(DOMContentLoaded)
            iframe.contentWindow.dispatchEvent(WindowLoaded)
            clearTimeout(timer)
        },100)
    }
    //end-1

    //start2-处理iframe高度自适应
    function reinitIframe(){
        var bHeight = iframeDoc.body.scrollHeight;
        var dHeight = iframeDoc.documentElement.scrollHeight;
        var height = Math.max(bHeight, dHeight);
        iframe.height = height;
    }
    window.setInterval(reinitIframe, 200);
    //end-2

    var code = document.getElementById('code');
    var worker = new Worker('high-worker.js');
    var xhr = new XMLHttpRequest()
    worker.onmessage = function(event){
        code.innerHTML = event.data;
        worker.terminate()
    }
    xhr.open('get',code.getAttribute('data-file'))
    xhr.responseType = 'text'
    xhr.onreadystatechange = function(){
        if(xhr.status<400&&xhr.readyState===xhr.DONE){
            iframeDoc.write(xhr.responseText)
            dispatchEvts()
            worker.postMessage(xhr.responseText);
        }
    }
    xhr.send()

});