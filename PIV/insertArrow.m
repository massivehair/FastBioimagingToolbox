function Annotated = insertArrow(Image, Positions, varargin)
%%% Draw an arrow in Image
% Positions = [x1,y1,x2,y2]

ArrowLength = sqrt((Positions(3)-Positions(1)).^2 + (Positions(4)-Positions(2)).^2);

Parser = inputParser;

addParameter(Parser,'ArrowheadLongAngle',20*(pi/180),@isnumeric);
addParameter(Parser,'ArrowheadShortAngle',40*(pi/180),@isnumeric);
addParameter(Parser,'ArrowheadSize',20,@isnumeric);

addParameter(Parser,'LineWidth',1,@isnumeric);
addParameter(Parser,'Opacity',1,@isnumeric);
addParameter(Parser,'Color','white');

parse(Parser,varargin{:});

% Draw the line
Annotated = insertShape(Image,'Line',Positions, 'LineWidth', Parser.Results.LineWidth, ...
    'Color', Parser.Results.Color, 'Opacity', Parser.Results.Opacity);

% Draw the arrow

ArrowAngle = atan2((Positions(4)-Positions(2)), (Positions(3)-Positions(1)));
Angles = zeros(1,3);
Angles(1) = ArrowAngle + (pi-Parser.Results.ArrowheadLongAngle);
Angles(2) = ArrowAngle - Parser.Results.ArrowheadShortAngle;
Angles(3) = ArrowAngle + Parser.Results.ArrowheadShortAngle - pi;
Lengths = zeros(1,3);
Lengths(1) = Parser.Results.ArrowheadSize;
Lengths(2) = sin(Parser.Results.ArrowheadLongAngle).*Parser.Results.ArrowheadSize./...
    sin(Parser.Results.ArrowheadShortAngle);
Lengths(3) = Lengths(2);

PolyPositions = zeros(1,8);
PolyPositions(1:2) = [Positions(3), Positions(4)];
for index = 1:3
    PolyPositions(index*2+1) = PolyPositions(index*2-1) + Lengths(index)*cos(Angles(index));
    PolyPositions(index*2+2) = PolyPositions(index*2) + Lengths(index)*sin(Angles(index));
end

Annotated = insertShape(Annotated,'FilledPolygon',PolyPositions,'LineWidth', Parser.Results.LineWidth, ...
    'Color', Parser.Results.Color, 'Opacity', Parser.Results.Opacity);