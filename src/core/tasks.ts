import type { Task, TaskPlan } from "./types"

export function planTasks(
  device: string,
  tasks: readonly Task[],
  group: "update" | "cleanup",
): TaskPlan {
  return {
    device,
    group,
    steps: tasks
      .filter((task) => task.group === group)
      .map((task) => ({
        id: task.id,
        argv: task.argv,
        ...(task.needs ? { needs: task.needs } : {}),
        destructive: task.destructive,
      })),
  }
}
