import {SeededRandom} from "../utils/randomid"
const seed = 123456; // Your seed value
const generator = new SeededRandom(seed);
const alphanumericString = generator.generateAlphanumeric(10); // Length of the string
console.log(alphanumericString);