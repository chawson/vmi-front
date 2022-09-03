(module
    (memory (export "mem") 1)
    (data (i32.const 0) "这是什么呢")
    (func (export "add") (param f64 f64) (result f64)
        local.get 0
        local.get 1
        f64.add
    )
)