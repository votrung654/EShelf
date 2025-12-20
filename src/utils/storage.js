// Utility functions for user-specific localStorage

export function getUserStorageKey(baseKey, userId) {
  if (!userId) return null;
  return `${baseKey}_${userId}`;
}

export function getUserData(baseKey, userId) {
  const key = getUserStorageKey(baseKey, userId);
  if (!key) return null;
  
  try {
    const data = localStorage.getItem(key);
    return data ? JSON.parse(data) : null;
  } catch {
    return null;
  }
}

export function setUserData(baseKey, userId, data) {
  const key = getUserStorageKey(baseKey, userId);
  if (!key) return false;
  
  try {
    localStorage.setItem(key, JSON.stringify(data));
    return true;
  } catch {
    return false;
  }
}

export function removeUserData(baseKey, userId) {
  const key = getUserStorageKey(baseKey, userId);
  if (!key) return;
  localStorage.removeItem(key);
}
