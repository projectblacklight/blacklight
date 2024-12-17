// Usage:
// ```
// const basicFunction = (entry) => console.log(entry)
// const debounced = debounce(basicFunction("I should only be called once"));
//
// debounced // does NOT print to the screen because it is invoked again less than 200 milliseconds later
// debounced // does print to the screen
// ```
export default function debounce(func, timeout = 200) {
    let timer;
    return (...args) => {
      clearTimeout(timer);
      timer = setTimeout(() => { func.apply(this, args); }, timeout);
    };
}
