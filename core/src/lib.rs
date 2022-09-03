use std::f64::consts::PI;

use js_sys::{WebAssembly, Object, Reflect, Function, Uint8ClampedArray, Date, JSON};
use serde::{Deserialize, Serialize};
use wasm_bindgen::{JsValue, prelude::{wasm_bindgen, Closure}, JsCast};
use wasm_bindgen_futures::JsFuture;
use web_sys::{window, Window, Document, HtmlElement, Request, RequestInit, Headers, Response, HtmlCanvasElement, CanvasRenderingContext2d};


const WASM: &[u8] = include_bytes!("add.wasm");

#[wasm_bindgen]
extern "C" {
    #[wasm_bindgen(js_namespace = console)]
    fn error(a: &str);
}

#[wasm_bindgen]
pub async fn run_async(a: f64, b: f64) -> Result<f64,JsValue> {
    // let wasm = await WebAssembly.initantiate(buffer, {})
    let wasm = JsFuture::from(WebAssembly::instantiate_buffer(WASM, &Object::new())).await?;
    // let instance = wasm.instance
    let instance: WebAssembly::Instance = Reflect::get(wasm.as_ref(), &"instance".into())?.dyn_into()?;

    // let exports = instance.exports
    let exports = instance.exports();

    // let add = exports.add
    let add = Reflect::get(exports.as_ref(), &"add".into())?.dyn_into::<Function>().expect("不存在add方法");

    let result = add.call2(&JsValue::undefined(), &a.into(), &b.into())?;

    let memory = Reflect::get(exports.as_ref(), &"mem".into())?.dyn_into::<WebAssembly::Memory>().expect("不存在可用的Memory");

    let bytes = Uint8ClampedArray::new_with_byte_offset_and_length(
        &memory.buffer(),
        0,
        3 * 5
    ).to_vec();

    error(String::from_utf8(bytes).expect("格式不合法").as_str());

    Ok(result.as_f64().unwrap())
}

#[wasm_bindgen]
pub fn create_h1() -> HtmlElement {
    let window = window().expect("没有window");
    let docuemnt = window.document().expect("没有document");
    let body = docuemnt.body().expect("没有body");
    let dom = docuemnt.create_element("h1").unwrap().dyn_into::<HtmlElement>().unwrap();
    dom.set_text_content(Some("标题h1"));
    body.append_child(&dom).expect("添加失败");
    return dom;
}

#[wasm_bindgen]
pub fn interval_clourse(window: &Window, docuemnt: &Document, body: &HtmlElement) -> i32 {
    let div = docuemnt.create_element("div").unwrap();
    body.append_child(&div).unwrap();
    let set_content = move || {
        div.set_text_content(
            Some(&String::from(Date::new_0().to_locale_time_string("zh-CN")))
        );
    };

    set_content();

    let clourse = Closure::wrap(Box::new(move || set_content()) as Box<dyn Fn()>);

    let interval = window.set_interval_with_callback_and_timeout_and_arguments_0(clourse.as_ref().unchecked_ref(), 1000i32).unwrap();

    clourse.forget();

    interval
}

#[wasm_bindgen]
pub fn listener_clourse(docuemnt: &Document) -> HtmlElement {
    let button = docuemnt.create_element("button").unwrap().dyn_into::<HtmlElement>().unwrap();

    let mut counter = 0;

    let clone_btn = button.clone();
    let set_content = move |times: i32| {
        clone_btn.set_text_content(Some(format!("点击了{}次", times).as_ref()));
    };

    set_content(0);

    let clourse = Closure::wrap(Box::new(move || {
        counter += 1;
        set_content(counter);
    }) as Box<dyn FnMut()>);

    button.set_onclick(
        Some(clourse.as_ref().unchecked_ref())
    );

    clourse.forget();

    button
}


#[derive(Serialize, Deserialize)]
struct LoginReq<'a> {
    account: &'a str,
    password: &'a str,
}

#[wasm_bindgen(getter_with_clone)]
#[derive(Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct LoginResData {
    pub base_url: String,
}

impl Clone for LoginResData {
    fn clone(&self) -> Self {
        Self { base_url: self.base_url.clone() }
    }
}

macro_rules! result_response {
    ($resp: ident, $data: tt) => {
        #[wasm_bindgen(getter_with_clone)]
        #[derive(Serialize, Deserialize)]
        pub struct $resp {
            pub code: i32,
            pub data: $data,
            pub message: String,
            pub reason: String
        }
    };
}

result_response!(LoginRes, LoginResData);


#[wasm_bindgen]
pub async fn login() -> Result<LoginRes, JsValue> {

    let win = window().expect("不存在window");

    let request = Request::new_with_str("/api/v1/auth/login").unwrap();

    let mut request_init = RequestInit::new();

    let headers = Headers::new().unwrap();

    headers.set("content-type", "application/json").unwrap();

    request_init.method("POST");
    request_init.headers(&headers.into());

    request_init.body(
        Some(
            &serde_json::to_string(&LoginReq {
                account: "",
                password: ""
            }).unwrap().into()
        )
    );

    let promise = JsFuture::from(win.fetch_with_request_and_init(&request, &request_init)).await?;
    let res = promise.dyn_into::<Response>()?;
    let buffer = JsFuture::from(res.array_buffer()?).await?;

    let bytes = Uint8ClampedArray::new(&buffer).to_vec();

    let res  = serde_json::from_slice::<LoginRes>(&bytes).unwrap();
    Ok(res)
}

#[wasm_bindgen]
pub fn draw_canvas(document: &Document) -> HtmlCanvasElement {
    let canvas = document.create_element("canvas").unwrap().dyn_into::<HtmlCanvasElement>().unwrap();
    let ctx = canvas.get_context("2d").unwrap().unwrap().dyn_into::<CanvasRenderingContext2d>().unwrap();

    canvas.set_width(200);
    canvas.set_height(200);

    ctx.save();

    ctx.set_fill_style(&"#ff0000".into());
    ctx.begin_path();
    ctx.arc_with_anticlockwise(120f64, 120f64, 40f64, -PI, PI, false).unwrap();
    ctx.close_path();
    ctx.fill();

    canvas
}