export const isNullOrEmpty = (value: any): boolean => {
  // test if value is falsely but not 0 or false
  return !value && value !== 0 && value !== false;
};

export const sleep = async (ms?: number): Promise<void> => {
  await new Promise(resolve => {
    setTimeout(resolve, ms || 1000);
  });
};
