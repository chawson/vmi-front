onmessage = (event) => {
    importScripts('https://cdn.staticfile.org/highlight.js/10.0.0/highlight.min.js');
    const result = self.hljs.highlightAuto(event.data);
    postMessage(result.value);
};
