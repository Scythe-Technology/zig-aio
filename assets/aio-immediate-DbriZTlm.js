import{u as l,j as s}from"./index-CeM8gXHB.js";const a={title:"AIO API",description:"undefined"};function e(r){const i={a:"a",code:"code",div:"div",h1:"h1",h2:"h2",h3:"h3",h4:"h4",header:"header",p:"p",pre:"pre",span:"span",...l(),...r.components};return s.jsxs(s.Fragment,{children:[s.jsx(i.header,{children:s.jsxs(i.h1,{id:"aio-api",children:["AIO API",s.jsx(i.a,{"aria-hidden":"true",tabIndex:"-1",href:"#aio-api",children:s.jsx(i.div,{"data-autolink-icon":!0})})]})}),`
`,s.jsxs(i.h2,{id:"immediate-io",children:["Immediate IO",s.jsx(i.a,{"aria-hidden":"true",tabIndex:"-1",href:"#immediate-io",children:s.jsx(i.div,{"data-autolink-icon":!0})})]}),`
`,s.jsxs(i.p,{children:["For immediate blocking IO, ",s.jsx(i.code,{children:"zig-aio"})," provides the following functions in the ",s.jsx(i.code,{children:"aio"})," module."]}),`
`,s.jsxs(i.h3,{id:"perform-a-single-operation",children:["Perform a single operation",s.jsx(i.a,{"aria-hidden":"true",tabIndex:"-1",href:"#perform-a-single-operation",children:s.jsx(i.div,{"data-autolink-icon":!0})})]}),`
`,s.jsxs(i.p,{children:[`Completes a single operation, the call blocks until it's complete.
Returns error of the operation if the operation failed.
Returns `,s.jsx(i.code,{children:"void"})," if there was no error."]}),`
`,s.jsx(i.pre,{className:"shiki shiki-themes github-light github-dark-dimmed",style:{backgroundColor:"#fff","--shiki-dark-bg":"#22272e",color:"#24292e","--shiki-dark":"#adbac7"},tabIndex:"0",children:s.jsx(i.code,{children:s.jsxs(i.span,{className:"line",children:[s.jsx(i.span,{style:{color:"#D73A49","--shiki-dark":"#F47067"},children:"try"}),s.jsx(i.span,{style:{color:"#E36209","--shiki-dark":"#F69D50"},children:" aio"}),s.jsx(i.span,{style:{color:"#24292E","--shiki-dark":"#ADBAC7"},children:"."}),s.jsx(i.span,{style:{color:"#6F42C1","--shiki-dark":"#DCBDFB"},children:"single"}),s.jsx(i.span,{style:{color:"#24292E","--shiki-dark":"#ADBAC7"},children:"("}),s.jsx(i.span,{style:{color:"#E36209","--shiki-dark":"#F69D50"},children:"aio"}),s.jsx(i.span,{style:{color:"#24292E","--shiki-dark":"#ADBAC7"},children:"."}),s.jsx(i.span,{style:{color:"#E36209","--shiki-dark":"#F69D50"},children:"Write"}),s.jsx(i.span,{style:{color:"#24292E","--shiki-dark":"#ADBAC7"},children:"{."}),s.jsx(i.span,{style:{color:"#E36209","--shiki-dark":"#F69D50"},children:"file"}),s.jsx(i.span,{style:{color:"#D73A49","--shiki-dark":"#F47067"},children:" ="}),s.jsx(i.span,{style:{color:"#E36209","--shiki-dark":"#F69D50"},children:" f"}),s.jsx(i.span,{style:{color:"#24292E","--shiki-dark":"#ADBAC7"},children:", ."}),s.jsx(i.span,{style:{color:"#E36209","--shiki-dark":"#F69D50"},children:"buffer"}),s.jsx(i.span,{style:{color:"#D73A49","--shiki-dark":"#F47067"},children:" ="}),s.jsx(i.span,{style:{color:"#032F62","--shiki-dark":"#96D0FF"},children:' "contents"'}),s.jsx(i.span,{style:{color:"#24292E","--shiki-dark":"#ADBAC7"},children:"});"})]})})}),`
`,s.jsxs(i.h3,{id:"perform-multiple-operations",children:["Perform multiple operations",s.jsx(i.a,{"aria-hidden":"true",tabIndex:"-1",href:"#perform-multiple-operations",children:s.jsx(i.div,{"data-autolink-icon":!0})})]}),`
`,s.jsxs(i.p,{children:[s.jsx(i.code,{children:"zig-aio"})," provides two methods for batching IO operations."]}),`
`,s.jsxs(i.h4,{id:"using-multi",children:["Using multi",s.jsx(i.a,{"aria-hidden":"true",tabIndex:"-1",href:"#using-multi",children:s.jsx(i.div,{"data-autolink-icon":!0})})]}),`
`,s.jsxs(i.p,{children:[`Completes a list of operations immediately, blocks until complete.
Returns `,s.jsx(i.code,{children:"error.SomeOperationFailed"}),` if any operation failed.
Returns `,s.jsx(i.code,{children:"void"})," if there were no errors."]}),`
`,s.jsx(i.pre,{className:"shiki shiki-themes github-light github-dark-dimmed",style:{backgroundColor:"#fff","--shiki-dark-bg":"#22272e",color:"#24292e","--shiki-dark":"#adbac7"},tabIndex:"0",children:s.jsxs(i.code,{children:[s.jsxs(i.span,{className:"line",children:[s.jsx(i.span,{style:{color:"#D73A49","--shiki-dark":"#F47067"},children:"var"}),s.jsx(i.span,{style:{color:"#E36209","--shiki-dark":"#F69D50"},children:" my_buffer"}),s.jsx(i.span,{style:{color:"#24292E","--shiki-dark":"#ADBAC7"},children:": ["}),s.jsx(i.span,{style:{color:"#005CC5","--shiki-dark":"#6CB6FF"},children:"1024"}),s.jsx(i.span,{style:{color:"#24292E","--shiki-dark":"#ADBAC7"},children:"]"}),s.jsx(i.span,{style:{color:"#D73A49","--shiki-dark":"#F47067"},children:"u8"}),s.jsx(i.span,{style:{color:"#D73A49","--shiki-dark":"#F47067"},children:" ="}),s.jsx(i.span,{style:{color:"#D73A49","--shiki-dark":"#F47067"},children:" undefined"}),s.jsx(i.span,{style:{color:"#24292E","--shiki-dark":"#ADBAC7"},children:";"})]}),`
`,s.jsxs(i.span,{className:"line",children:[s.jsx(i.span,{style:{color:"#D73A49","--shiki-dark":"#F47067"},children:"var"}),s.jsx(i.span,{style:{color:"#E36209","--shiki-dark":"#F69D50"},children:" my_len"}),s.jsx(i.span,{style:{color:"#24292E","--shiki-dark":"#ADBAC7"},children:": "}),s.jsx(i.span,{style:{color:"#D73A49","--shiki-dark":"#F47067"},children:"usize"}),s.jsx(i.span,{style:{color:"#D73A49","--shiki-dark":"#F47067"},children:" ="}),s.jsx(i.span,{style:{color:"#D73A49","--shiki-dark":"#F47067"},children:" undefined"}),s.jsx(i.span,{style:{color:"#24292E","--shiki-dark":"#ADBAC7"},children:";"})]}),`
`,s.jsx(i.span,{className:"line","data-empty-line":!0,children:" "}),`
`,s.jsxs(i.span,{className:"line",children:[s.jsx(i.span,{style:{color:"#D73A49","--shiki-dark":"#F47067"},children:"try"}),s.jsx(i.span,{style:{color:"#E36209","--shiki-dark":"#F69D50"},children:" aio"}),s.jsx(i.span,{style:{color:"#24292E","--shiki-dark":"#ADBAC7"},children:"."}),s.jsx(i.span,{style:{color:"#6F42C1","--shiki-dark":"#DCBDFB"},children:"multi"}),s.jsx(i.span,{style:{color:"#24292E","--shiki-dark":"#ADBAC7"},children:"(.{"})]}),`
`,s.jsxs(i.span,{className:"line",children:[s.jsx(i.span,{style:{color:"#E36209","--shiki-dark":"#F69D50"},children:"    aio"}),s.jsx(i.span,{style:{color:"#24292E","--shiki-dark":"#ADBAC7"},children:"."}),s.jsx(i.span,{style:{color:"#E36209","--shiki-dark":"#F69D50"},children:"Write"}),s.jsx(i.span,{style:{color:"#24292E","--shiki-dark":"#ADBAC7"},children:"{."}),s.jsx(i.span,{style:{color:"#E36209","--shiki-dark":"#F69D50"},children:"file"}),s.jsx(i.span,{style:{color:"#D73A49","--shiki-dark":"#F47067"},children:" ="}),s.jsx(i.span,{style:{color:"#E36209","--shiki-dark":"#F69D50"},children:" f"}),s.jsx(i.span,{style:{color:"#24292E","--shiki-dark":"#ADBAC7"},children:", ."}),s.jsx(i.span,{style:{color:"#E36209","--shiki-dark":"#F69D50"},children:"buffer"}),s.jsx(i.span,{style:{color:"#D73A49","--shiki-dark":"#F47067"},children:" ="}),s.jsx(i.span,{style:{color:"#032F62","--shiki-dark":"#96D0FF"},children:' "contents"'}),s.jsx(i.span,{style:{color:"#24292E","--shiki-dark":"#ADBAC7"},children:", ."}),s.jsx(i.span,{style:{color:"#E36209","--shiki-dark":"#F69D50"},children:"link"}),s.jsx(i.span,{style:{color:"#D73A49","--shiki-dark":"#F47067"},children:" ="}),s.jsx(i.span,{style:{color:"#24292E","--shiki-dark":"#ADBAC7"},children:" ."}),s.jsx(i.span,{style:{color:"#E36209","--shiki-dark":"#F69D50"},children:"soft"}),s.jsx(i.span,{style:{color:"#24292E","--shiki-dark":"#ADBAC7"},children:"},"})]}),`
`,s.jsxs(i.span,{className:"line",children:[s.jsx(i.span,{style:{color:"#E36209","--shiki-dark":"#F69D50"},children:"    aio"}),s.jsx(i.span,{style:{color:"#24292E","--shiki-dark":"#ADBAC7"},children:"."}),s.jsx(i.span,{style:{color:"#E36209","--shiki-dark":"#F69D50"},children:"Read"}),s.jsx(i.span,{style:{color:"#24292E","--shiki-dark":"#ADBAC7"},children:"{."}),s.jsx(i.span,{style:{color:"#E36209","--shiki-dark":"#F69D50"},children:"file"}),s.jsx(i.span,{style:{color:"#D73A49","--shiki-dark":"#F47067"},children:" ="}),s.jsx(i.span,{style:{color:"#E36209","--shiki-dark":"#F69D50"},children:" f"}),s.jsx(i.span,{style:{color:"#24292E","--shiki-dark":"#ADBAC7"},children:", ."}),s.jsx(i.span,{style:{color:"#E36209","--shiki-dark":"#F69D50"},children:"buffer"}),s.jsx(i.span,{style:{color:"#D73A49","--shiki-dark":"#F47067"},children:" ="}),s.jsx(i.span,{style:{color:"#D73A49","--shiki-dark":"#F47067"},children:" &"}),s.jsx(i.span,{style:{color:"#E36209","--shiki-dark":"#F69D50"},children:"my_buffer"}),s.jsx(i.span,{style:{color:"#24292E","--shiki-dark":"#ADBAC7"},children:", ."}),s.jsx(i.span,{style:{color:"#E36209","--shiki-dark":"#F69D50"},children:"out_read"}),s.jsx(i.span,{style:{color:"#D73A49","--shiki-dark":"#F47067"},children:" ="}),s.jsx(i.span,{style:{color:"#D73A49","--shiki-dark":"#F47067"},children:" &"}),s.jsx(i.span,{style:{color:"#E36209","--shiki-dark":"#F69D50"},children:"my_len"}),s.jsx(i.span,{style:{color:"#24292E","--shiki-dark":"#ADBAC7"},children:"},"})]}),`
`,s.jsx(i.span,{className:"line",children:s.jsx(i.span,{style:{color:"#24292E","--shiki-dark":"#ADBAC7"},children:"});"})})]})}),`
`,s.jsxs(i.p,{children:["The ",s.jsx(i.code,{children:".link"}),` field of operation can be used to link the operation to the next operation.
When linking operations, the next operation won't start until this operation is complete.`]}),`
`,s.jsxs(i.p,{children:[s.jsx(i.code,{children:"soft"}),` link will propagate failure to next operations in the link chain.
`,s.jsx(i.code,{children:"hard"})," link will not propagate failure, and the next operation starts normally."]}),`
`,s.jsxs(i.h4,{id:"using-complete",children:["Using complete",s.jsx(i.a,{"aria-hidden":"true",tabIndex:"-1",href:"#using-complete",children:s.jsx(i.div,{"data-autolink-icon":!0})})]}),`
`,s.jsxs(i.p,{children:["Complete is similar to multi, but it will not return ",s.jsx(i.code,{children:"error.SomeOperationFailed"}),` in case any of the operations fail.
Instead complete returns the number of errors occured. To find out which operations failed, errors have to be stored
somewhere by setting the `,s.jsx(i.code,{children:".out_error"}),` field of the operation. The complete call may still fail in implementation
defined ways, such as running out of system resources.`]}),`
`,s.jsx(i.pre,{className:"shiki shiki-themes github-light github-dark-dimmed",style:{backgroundColor:"#fff","--shiki-dark-bg":"#22272e",color:"#24292e","--shiki-dark":"#adbac7"},tabIndex:"0",children:s.jsxs(i.code,{children:[s.jsxs(i.span,{className:"line",children:[s.jsx(i.span,{style:{color:"#D73A49","--shiki-dark":"#F47067"},children:"var"}),s.jsx(i.span,{style:{color:"#E36209","--shiki-dark":"#F69D50"},children:" my_buffer"}),s.jsx(i.span,{style:{color:"#24292E","--shiki-dark":"#ADBAC7"},children:": ["}),s.jsx(i.span,{style:{color:"#005CC5","--shiki-dark":"#6CB6FF"},children:"1024"}),s.jsx(i.span,{style:{color:"#24292E","--shiki-dark":"#ADBAC7"},children:"]"}),s.jsx(i.span,{style:{color:"#D73A49","--shiki-dark":"#F47067"},children:"u8"}),s.jsx(i.span,{style:{color:"#D73A49","--shiki-dark":"#F47067"},children:" ="}),s.jsx(i.span,{style:{color:"#D73A49","--shiki-dark":"#F47067"},children:" undefined"}),s.jsx(i.span,{style:{color:"#24292E","--shiki-dark":"#ADBAC7"},children:";"})]}),`
`,s.jsxs(i.span,{className:"line",children:[s.jsx(i.span,{style:{color:"#D73A49","--shiki-dark":"#F47067"},children:"var"}),s.jsx(i.span,{style:{color:"#E36209","--shiki-dark":"#F69D50"},children:" my_len"}),s.jsx(i.span,{style:{color:"#24292E","--shiki-dark":"#ADBAC7"},children:": "}),s.jsx(i.span,{style:{color:"#D73A49","--shiki-dark":"#F47067"},children:"usize"}),s.jsx(i.span,{style:{color:"#D73A49","--shiki-dark":"#F47067"},children:" ="}),s.jsx(i.span,{style:{color:"#D73A49","--shiki-dark":"#F47067"},children:" undefined"}),s.jsx(i.span,{style:{color:"#24292E","--shiki-dark":"#ADBAC7"},children:";"})]}),`
`,s.jsxs(i.span,{className:"line",children:[s.jsx(i.span,{style:{color:"#D73A49","--shiki-dark":"#F47067"},children:"var"}),s.jsx(i.span,{style:{color:"#E36209","--shiki-dark":"#F69D50"},children:" write_error"}),s.jsx(i.span,{style:{color:"#24292E","--shiki-dark":"#ADBAC7"},children:": "}),s.jsx(i.span,{style:{color:"#E36209","--shiki-dark":"#F69D50"},children:"std"}),s.jsx(i.span,{style:{color:"#24292E","--shiki-dark":"#ADBAC7"},children:"."}),s.jsx(i.span,{style:{color:"#E36209","--shiki-dark":"#F69D50"},children:"posix"}),s.jsx(i.span,{style:{color:"#24292E","--shiki-dark":"#ADBAC7"},children:"."}),s.jsx(i.span,{style:{color:"#E36209","--shiki-dark":"#F69D50"},children:"WriteError"}),s.jsx(i.span,{style:{color:"#D73A49","--shiki-dark":"#F47067"},children:" ="}),s.jsx(i.span,{style:{color:"#D73A49","--shiki-dark":"#F47067"},children:" undefined"}),s.jsx(i.span,{style:{color:"#24292E","--shiki-dark":"#ADBAC7"},children:";"})]}),`
`,s.jsxs(i.span,{className:"line",children:[s.jsx(i.span,{style:{color:"#D73A49","--shiki-dark":"#F47067"},children:"var"}),s.jsx(i.span,{style:{color:"#E36209","--shiki-dark":"#F69D50"},children:" read_error"}),s.jsx(i.span,{style:{color:"#24292E","--shiki-dark":"#ADBAC7"},children:": "}),s.jsx(i.span,{style:{color:"#E36209","--shiki-dark":"#F69D50"},children:"std"}),s.jsx(i.span,{style:{color:"#24292E","--shiki-dark":"#ADBAC7"},children:"."}),s.jsx(i.span,{style:{color:"#E36209","--shiki-dark":"#F69D50"},children:"posix"}),s.jsx(i.span,{style:{color:"#24292E","--shiki-dark":"#ADBAC7"},children:"."}),s.jsx(i.span,{style:{color:"#E36209","--shiki-dark":"#F69D50"},children:"ReadError"}),s.jsx(i.span,{style:{color:"#D73A49","--shiki-dark":"#F47067"},children:" ="}),s.jsx(i.span,{style:{color:"#D73A49","--shiki-dark":"#F47067"},children:" undefined"}),s.jsx(i.span,{style:{color:"#24292E","--shiki-dark":"#ADBAC7"},children:";"})]}),`
`,s.jsx(i.span,{className:"line","data-empty-line":!0,children:" "}),`
`,s.jsxs(i.span,{className:"line",children:[s.jsx(i.span,{style:{color:"#D73A49","--shiki-dark":"#F47067"},children:"const"}),s.jsx(i.span,{style:{color:"#E36209","--shiki-dark":"#F69D50"},children:" res"}),s.jsx(i.span,{style:{color:"#D73A49","--shiki-dark":"#F47067"},children:" ="}),s.jsx(i.span,{style:{color:"#D73A49","--shiki-dark":"#F47067"},children:" try"}),s.jsx(i.span,{style:{color:"#E36209","--shiki-dark":"#F69D50"},children:" aio"}),s.jsx(i.span,{style:{color:"#24292E","--shiki-dark":"#ADBAC7"},children:"."}),s.jsx(i.span,{style:{color:"#6F42C1","--shiki-dark":"#DCBDFB"},children:"complete"}),s.jsx(i.span,{style:{color:"#24292E","--shiki-dark":"#ADBAC7"},children:"(.{"})]}),`
`,s.jsxs(i.span,{className:"line",children:[s.jsx(i.span,{style:{color:"#E36209","--shiki-dark":"#F69D50"},children:"    aio"}),s.jsx(i.span,{style:{color:"#24292E","--shiki-dark":"#ADBAC7"},children:"."}),s.jsx(i.span,{style:{color:"#E36209","--shiki-dark":"#F69D50"},children:"Write"}),s.jsx(i.span,{style:{color:"#24292E","--shiki-dark":"#ADBAC7"},children:"{."}),s.jsx(i.span,{style:{color:"#E36209","--shiki-dark":"#F69D50"},children:"file"}),s.jsx(i.span,{style:{color:"#D73A49","--shiki-dark":"#F47067"},children:" ="}),s.jsx(i.span,{style:{color:"#E36209","--shiki-dark":"#F69D50"},children:" f"}),s.jsx(i.span,{style:{color:"#24292E","--shiki-dark":"#ADBAC7"},children:", ."}),s.jsx(i.span,{style:{color:"#E36209","--shiki-dark":"#F69D50"},children:"buffer"}),s.jsx(i.span,{style:{color:"#D73A49","--shiki-dark":"#F47067"},children:" ="}),s.jsx(i.span,{style:{color:"#032F62","--shiki-dark":"#96D0FF"},children:' "contents"'}),s.jsx(i.span,{style:{color:"#24292E","--shiki-dark":"#ADBAC7"},children:", ."}),s.jsx(i.span,{style:{color:"#E36209","--shiki-dark":"#F69D50"},children:"out_error"}),s.jsx(i.span,{style:{color:"#D73A49","--shiki-dark":"#F47067"},children:" ="}),s.jsx(i.span,{style:{color:"#D73A49","--shiki-dark":"#F47067"},children:" &"}),s.jsx(i.span,{style:{color:"#E36209","--shiki-dark":"#F69D50"},children:"write_error"}),s.jsx(i.span,{style:{color:"#24292E","--shiki-dark":"#ADBAC7"},children:", ."}),s.jsx(i.span,{style:{color:"#E36209","--shiki-dark":"#F69D50"},children:"link"}),s.jsx(i.span,{style:{color:"#D73A49","--shiki-dark":"#F47067"},children:" ="}),s.jsx(i.span,{style:{color:"#24292E","--shiki-dark":"#ADBAC7"},children:" ."}),s.jsx(i.span,{style:{color:"#E36209","--shiki-dark":"#F69D50"},children:"soft"}),s.jsx(i.span,{style:{color:"#24292E","--shiki-dark":"#ADBAC7"},children:"},"})]}),`
`,s.jsxs(i.span,{className:"line",children:[s.jsx(i.span,{style:{color:"#E36209","--shiki-dark":"#F69D50"},children:"    aio"}),s.jsx(i.span,{style:{color:"#24292E","--shiki-dark":"#ADBAC7"},children:"."}),s.jsx(i.span,{style:{color:"#E36209","--shiki-dark":"#F69D50"},children:"Read"}),s.jsx(i.span,{style:{color:"#24292E","--shiki-dark":"#ADBAC7"},children:"{."}),s.jsx(i.span,{style:{color:"#E36209","--shiki-dark":"#F69D50"},children:"file"}),s.jsx(i.span,{style:{color:"#D73A49","--shiki-dark":"#F47067"},children:" ="}),s.jsx(i.span,{style:{color:"#E36209","--shiki-dark":"#F69D50"},children:" f"}),s.jsx(i.span,{style:{color:"#24292E","--shiki-dark":"#ADBAC7"},children:", ."}),s.jsx(i.span,{style:{color:"#E36209","--shiki-dark":"#F69D50"},children:"buffer"}),s.jsx(i.span,{style:{color:"#D73A49","--shiki-dark":"#F47067"},children:" ="}),s.jsx(i.span,{style:{color:"#D73A49","--shiki-dark":"#F47067"},children:" &"}),s.jsx(i.span,{style:{color:"#E36209","--shiki-dark":"#F69D50"},children:"my_buffer"}),s.jsx(i.span,{style:{color:"#24292E","--shiki-dark":"#ADBAC7"},children:", ."}),s.jsx(i.span,{style:{color:"#E36209","--shiki-dark":"#F69D50"},children:"out_error"}),s.jsx(i.span,{style:{color:"#D73A49","--shiki-dark":"#F47067"},children:" ="}),s.jsx(i.span,{style:{color:"#D73A49","--shiki-dark":"#F47067"},children:" &"}),s.jsx(i.span,{style:{color:"#E36209","--shiki-dark":"#F69D50"},children:"read_error"}),s.jsx(i.span,{style:{color:"#24292E","--shiki-dark":"#ADBAC7"},children:", ."}),s.jsx(i.span,{style:{color:"#E36209","--shiki-dark":"#F69D50"},children:"out_read"}),s.jsx(i.span,{style:{color:"#D73A49","--shiki-dark":"#F47067"},children:" ="}),s.jsx(i.span,{style:{color:"#D73A49","--shiki-dark":"#F47067"},children:" &"}),s.jsx(i.span,{style:{color:"#E36209","--shiki-dark":"#F69D50"},children:"my_len"}),s.jsx(i.span,{style:{color:"#24292E","--shiki-dark":"#ADBAC7"},children:"},"})]}),`
`,s.jsx(i.span,{className:"line",children:s.jsx(i.span,{style:{color:"#24292E","--shiki-dark":"#ADBAC7"},children:"});"})}),`
`,s.jsx(i.span,{className:"line","data-empty-line":!0,children:" "}),`
`,s.jsxs(i.span,{className:"line",children:[s.jsx(i.span,{style:{color:"#D73A49","--shiki-dark":"#F47067"},children:"if"}),s.jsx(i.span,{style:{color:"#24292E","--shiki-dark":"#ADBAC7"},children:" ("}),s.jsx(i.span,{style:{color:"#E36209","--shiki-dark":"#F69D50"},children:"res"}),s.jsx(i.span,{style:{color:"#24292E","--shiki-dark":"#ADBAC7"},children:"."}),s.jsx(i.span,{style:{color:"#E36209","--shiki-dark":"#F69D50"},children:"num_errors"}),s.jsx(i.span,{style:{color:"#D73A49","--shiki-dark":"#F47067"},children:" >"}),s.jsx(i.span,{style:{color:"#005CC5","--shiki-dark":"#6CB6FF"},children:" 0"}),s.jsx(i.span,{style:{color:"#24292E","--shiki-dark":"#ADBAC7"},children:") {"})]}),`
`,s.jsxs(i.span,{className:"line",children:[s.jsx(i.span,{style:{color:"#D73A49","--shiki-dark":"#F47067"},children:"    if"}),s.jsx(i.span,{style:{color:"#24292E","--shiki-dark":"#ADBAC7"},children:" ("}),s.jsx(i.span,{style:{color:"#E36209","--shiki-dark":"#F69D50"},children:"write_error"}),s.jsx(i.span,{style:{color:"#D73A49","--shiki-dark":"#F47067"},children:" !="}),s.jsx(i.span,{style:{color:"#D73A49","--shiki-dark":"#F47067"},children:" error"}),s.jsx(i.span,{style:{color:"#24292E","--shiki-dark":"#ADBAC7"},children:"."}),s.jsx(i.span,{style:{color:"#E36209","--shiki-dark":"#F69D50"},children:"Success"}),s.jsx(i.span,{style:{color:"#24292E","--shiki-dark":"#ADBAC7"},children:") "}),s.jsx(i.span,{style:{color:"#005CC5","--shiki-dark":"#6CB6FF"},children:"@panic"}),s.jsx(i.span,{style:{color:"#24292E","--shiki-dark":"#ADBAC7"},children:"("}),s.jsx(i.span,{style:{color:"#032F62","--shiki-dark":"#96D0FF"},children:'"write failed"'}),s.jsx(i.span,{style:{color:"#24292E","--shiki-dark":"#ADBAC7"},children:");"})]}),`
`,s.jsxs(i.span,{className:"line",children:[s.jsx(i.span,{style:{color:"#D73A49","--shiki-dark":"#F47067"},children:"    if"}),s.jsx(i.span,{style:{color:"#24292E","--shiki-dark":"#ADBAC7"},children:" ("}),s.jsx(i.span,{style:{color:"#E36209","--shiki-dark":"#F69D50"},children:"read_error"}),s.jsx(i.span,{style:{color:"#D73A49","--shiki-dark":"#F47067"},children:" !="}),s.jsx(i.span,{style:{color:"#D73A49","--shiki-dark":"#F47067"},children:" error"}),s.jsx(i.span,{style:{color:"#24292E","--shiki-dark":"#ADBAC7"},children:"."}),s.jsx(i.span,{style:{color:"#E36209","--shiki-dark":"#F69D50"},children:"Success"}),s.jsx(i.span,{style:{color:"#24292E","--shiki-dark":"#ADBAC7"},children:") "}),s.jsx(i.span,{style:{color:"#005CC5","--shiki-dark":"#6CB6FF"},children:"@panic"}),s.jsx(i.span,{style:{color:"#24292E","--shiki-dark":"#ADBAC7"},children:"("}),s.jsx(i.span,{style:{color:"#032F62","--shiki-dark":"#96D0FF"},children:'"read failed"'}),s.jsx(i.span,{style:{color:"#24292E","--shiki-dark":"#ADBAC7"},children:");"})]}),`
`,s.jsx(i.span,{className:"line",children:s.jsx(i.span,{style:{color:"#24292E","--shiki-dark":"#ADBAC7"},children:"}"})})]})})]})}function o(r={}){const{wrapper:i}={...l(),...r.components};return i?s.jsx(i,{...r,children:s.jsx(e,{...r})}):e(r)}export{o as default,a as frontmatter};
