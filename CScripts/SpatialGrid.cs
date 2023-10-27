using Godot;
using System;
using System.Collections.Generic;

using WaterParticle;

using Vector2 = Godot.Vector2;

namespace SpatialHashGrid {
	public partial class SpatialGrid : Node
	{
		public Dictionary<Vector2I, List<Particle>> grid;
		private float cellSize;

		public SpatialGrid(float cellSize)
		{
			this.cellSize = cellSize;
			 grid = new Dictionary<Vector2I, List<Particle>>();

		}

		// Helper function to convert real-world coordinates to grid cell coordinates
		public Vector2I GetCell(Particle p)
		{
			int x = (int)Math.Floor(p.Position[0] / cellSize);
			int y = (int)Math.Floor(p.Position[1] / cellSize);
			return new Vector2I(x, y);
		}

		// Insert a particle into the spatial hash grid
		public void Insert(Particle p)
		{
			Vector2I cell = GetCell(p);

			if (!grid.ContainsKey(cell))
			{
				grid[cell] = new List<Particle>();
			}

			grid[cell].Add(p);
		}

		// Retrieve particle densities and positions in a specific cell
		public List<Particle> GetParticlesInCell(Vector2I cell)
		{
			if (grid.ContainsKey(cell))
			{
				return grid[cell];
			}
			else
			{
				return new List<Particle>();
			}
		}

		// Retrieve particles in the neighboring cells (including diagonals)
		public List<Particle> GetParticlesInNeighboringCells(Particle p)
		{
			Vector2I cell = GetCell(p);
			List<Particle> particles = new List<Particle>();

			for (int xOffset = -1; xOffset <= 1; xOffset++)
			{
				for (int yOffset = -1; yOffset <= 1; yOffset++)
				{
					Vector2I neighborCell = new Vector2I(cell[0] + xOffset, cell[1] + yOffset);
					particles.AddRange(GetParticlesInCell(neighborCell));
				}
			}

			return particles;
		}

		public void PrintGrid() {
			string output = "";
			foreach (var kvp in grid)
			{
				output += "Key: " + kvp.Key;
				output += " ";
				output += "Count: " + kvp.Value.Count;
				output += " ";
			}
			
			GD.Print(output);
		}
		
	}
}