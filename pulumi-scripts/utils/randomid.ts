export class SeededRandom {
    private seed: number;
  
    constructor(seed: number) {
      this.seed = seed;
    }
  
    // Linear congruential generator (LCG) implementation
    private random(): number {
      const a = 1664525;
      const c = 1013904223;
      const m = 2 ** 32;
      this.seed = (a * this.seed + c) % m;
      return this.seed / m;
    }
  
    // Generate a random alphanumeric string of a given length
    generateAlphanumeric(length: number): string {
      const characters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
      let result = '';
      for (let i = 0; i < length; i++) {
        const randomIndex = Math.floor(this.random() * characters.length);
        result += characters.charAt(randomIndex);
      }
      return result;
    }
  }


  
  
  